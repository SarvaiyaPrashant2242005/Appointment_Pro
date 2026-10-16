const { Op } = require('sequelize');
const { sequelize } = require('../../config/database');
const { BusinessOperatingHour, BusinessScheduleBreak } = require('./index');
const { Business, BusinessMember } = require('../businesses');

class AvailabilityService {
    /**
     * Helper to verify business ownership or resolve user's active business
     */
    async _resolveBusiness(ownerId, requestedBusinessId) {
        if (requestedBusinessId) {
            const business = await Business.findOne({
                where: { id: requestedBusinessId },
            });

            if (!business) {
                const error = new Error('Business not found.');
                error.statusCode = 404;
                error.messageToShow = 'The requested business could not be found.';
                throw error;
            }

            const isOwner = business.owner_id === ownerId;
            if (!isOwner) {
                const membership = await BusinessMember.findOne({
                    where: {
                        business_id: requestedBusinessId,
                        user_id: ownerId,
                        is_active: true,
                    },
                });

                if (!membership) {
                    const error = new Error('Unauthorized business access.');
                    error.statusCode = 403;
                    error.messageToShow = 'You do not have permission to manage operating hours for this business.';
                    throw error;
                }
            }

            return business;
        }

        const activeBusiness = await Business.findOne({
            where: {
                owner_id: ownerId,
                is_active: true,
            },
        });

        if (!activeBusiness) {
            const error = new Error('No active business found.');
            error.statusCode = 400;
            error.messageToShow = 'Please select or create an active business before configuring operating hours.';
            throw error;
        }

        return activeBusiness;
    }

    /**
     * Default weekly schedule conforming to Flutter BusinessAvailability.defaultFor()
     */
    _getDefaultDaySchedule(dayOfWeek) {
        if (dayOfWeek >= 1 && dayOfWeek <= 5) {
            // Mon - Fri: 09:00 - 18:00 with lunch break 13:00 - 14:00
            return {
                dayOfWeek,
                isOpen: true,
                openTime: '09:00',
                closeTime: '18:00',
                breaks: [{ breakName: 'Lunch Break', startTime: '13:00', endTime: '14:00' }],
            };
        } else if (dayOfWeek === 6) {
            // Saturday: 10:00 - 16:00
            return {
                dayOfWeek,
                isOpen: true,
                openTime: '10:00',
                closeTime: '16:00',
                breaks: [],
            };
        } else {
            // Sunday: Closed
            return {
                dayOfWeek: 7,
                isOpen: false,
                openTime: '09:00',
                closeTime: '18:00',
                breaks: [],
            };
        }
    }

    /**
     * Get operating hours & breaks for business
     */
    async getBusinessOperatingHours(ownerId, requestedBusinessId) {
        const business = await this._resolveBusiness(ownerId, requestedBusinessId);

        const existingRecords = await BusinessOperatingHour.findAll({
            where: { business_id: business.id },
            include: [{ model: BusinessScheduleBreak, as: 'breaks' }],
            order: [['day_of_week', 'ASC']],
        });

        const weeklySchedule = {};
        const operatingHoursList = [];

        // Build a complete 7-day schedule (filling in defaults if a day was not yet saved)
        for (let day = 1; day <= 7; day++) {
            const record = existingRecords.find((r) => r.day_of_week === day);
            if (record) {
                const clientData = record.toClientJSON();
                weeklySchedule[day] = clientData;
                operatingHoursList.push(clientData);
            } else {
                const defaultDay = this._getDefaultDaySchedule(day);
                weeklySchedule[day] = defaultDay;
                operatingHoursList.push(defaultDay);
            }
        }

        return {
            businessId: business.id,
            businessName: business.name,
            timezone: business.timezone || 'Asia/Kolkata',
            weeklySchedule,
            operatingHours: operatingHoursList,
            messageToShow: 'Business operating hours retrieved successfully.',
        };
    }

    /**
     * Update/save weekly schedule & breaks in an atomic transaction
     */
    async updateBusinessOperatingHours(ownerId, payload) {
        const business = await this._resolveBusiness(ownerId, payload.businessId || payload.business_id);

        // Normalize incoming schedule data (Map of 1..7, array of days, etc.)
        const scheduleInput = payload.weeklySchedule || payload.schedule || payload.operatingHours;
        let dayItems = [];

        if (Array.isArray(scheduleInput)) {
            dayItems = scheduleInput;
        } else if (scheduleInput && typeof scheduleInput === 'object') {
            dayItems = Object.entries(scheduleInput).map(([key, val]) => ({
                dayOfWeek: val.dayOfWeek || val.day_of_week || parseInt(key, 10),
                ...val,
            }));
        }

        const transaction = await sequelize.transaction();
        try {
            for (const item of dayItems) {
                const dayOfWeek = parseInt(item.dayOfWeek || item.day_of_week, 10);
                if (isNaN(dayOfWeek) || dayOfWeek < 1 || dayOfWeek > 7) continue;

                const isOpen = item.isOpen !== undefined ? Boolean(item.isOpen) : (item.is_open !== undefined ? Boolean(item.is_open) : true);
                const openTime = item.openTime || item.open_time || '09:00';
                const closeTime = item.closeTime || item.close_time || '18:00';
                const breaks = Array.isArray(item.breaks) ? item.breaks : [];

                const formattedOpen = openTime.length === 5 ? `${openTime}:00` : openTime;
                const formattedClose = closeTime.length === 5 ? `${closeTime}:00` : closeTime;

                // Find or create operating hour for this day
                let [hourRecord] = await BusinessOperatingHour.findOrCreate({
                    where: {
                        business_id: business.id,
                        day_of_week: dayOfWeek,
                    },
                    defaults: {
                        business_id: business.id,
                        day_of_week: dayOfWeek,
                        is_open: isOpen,
                        open_time: formattedOpen,
                        close_time: formattedClose,
                    },
                    transaction,
                });

                // Update hours
                await hourRecord.update(
                    {
                        is_open: isOpen,
                        open_time: formattedOpen,
                        close_time: formattedClose,
                    },
                    { transaction }
                );

                // Replace breaks for this day
                await BusinessScheduleBreak.destroy({
                    where: { operating_hour_id: hourRecord.id },
                    transaction,
                });

                if (isOpen && breaks.length > 0) {
                    const breakRecords = breaks.map((b) => {
                        const bStart = b.startTime || b.start_time || '13:00';
                        const bEnd = b.endTime || b.end_time || '14:00';
                        return {
                            operating_hour_id: hourRecord.id,
                            break_name: b.breakName || b.break_name || 'Break',
                            start_time: bStart.length === 5 ? `${bStart}:00` : bStart,
                            end_time: bEnd.length === 5 ? `${bEnd}:00` : bEnd,
                        };
                    });
                    await BusinessScheduleBreak.bulkCreate(breakRecords, { transaction });
                }
            }

            await transaction.commit();

            // Fetch updated records
            return await this.getBusinessOperatingHours(ownerId, business.id);
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }

    /**
     * Toggle open/closed status for a single day
     */
    async toggleDayStatus(ownerId, dayOfWeek, requestedBusinessId) {
        const business = await this._resolveBusiness(ownerId, requestedBusinessId);
        const day = parseInt(dayOfWeek, 10);

        let hourRecord = await BusinessOperatingHour.findOne({
            where: {
                business_id: business.id,
                day_of_week: day,
            },
            include: [{ model: BusinessScheduleBreak, as: 'breaks' }],
        });

        let newStatus = false;
        if (!hourRecord) {
            const def = this._getDefaultDaySchedule(day);
            newStatus = !def.isOpen;
            hourRecord = await BusinessOperatingHour.create({
                business_id: business.id,
                day_of_week: day,
                is_open: newStatus,
                open_time: `${def.openTime}:00`,
                close_time: `${def.closeTime}:00`,
            });
        } else {
            newStatus = !hourRecord.is_open;
            await hourRecord.update({ is_open: newStatus });
            await hourRecord.reload();
        }

        const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const dayName = dayNames[day] || `Day ${day}`;

        return {
            day: hourRecord.toClientJSON(),
            messageToShow: `${dayName} is now ${newStatus ? 'open' : 'closed'} for ${business.name}.`,
        };
    }

    /**
     * Public lookup by business slug (for customer online booking)
     */
    async getPublicOperatingHoursBySlug(businessSlug) {
        const cleanSlug = businessSlug.trim().toLowerCase();

        const business = await Business.findOne({
            where: { slug: cleanSlug },
            attributes: ['id', 'name', 'slug', 'timezone', 'is_active'],
        });

        if (!business) {
            const error = new Error('Business not found with this booking link.');
            error.statusCode = 404;
            error.messageToShow = 'No business was found with this booking link.';
            throw error;
        }

        const existingRecords = await BusinessOperatingHour.findAll({
            where: { business_id: business.id },
            include: [{ model: BusinessScheduleBreak, as: 'breaks' }],
            order: [['day_of_week', 'ASC']],
        });

        const weeklySchedule = {};
        const operatingHoursList = [];

        for (let day = 1; day <= 7; day++) {
            const record = existingRecords.find((r) => r.day_of_week === day);
            if (record) {
                const clientData = record.toClientJSON();
                weeklySchedule[day] = clientData;
                operatingHoursList.push(clientData);
            } else {
                const defaultDay = this._getDefaultDaySchedule(day);
                weeklySchedule[day] = defaultDay;
                operatingHoursList.push(defaultDay);
            }
        }

        return {
            business: business.toClientJSON(),
            weeklySchedule,
            operatingHours: operatingHoursList,
            timezone: business.timezone || 'Asia/Kolkata',
            messageToShow: 'Business operating hours loaded successfully.',
        };
    }
}

module.exports = new AvailabilityService();

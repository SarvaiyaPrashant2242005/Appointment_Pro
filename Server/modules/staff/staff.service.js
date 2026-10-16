const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { sequelize } = require('../../config/database');
const { Staff, StaffService: StaffServiceModel, StaffOperatingHour, StaffScheduleBreak } = require('./index');
const { Business, BusinessMember } = require('../businesses');
const { Service } = require('../services');
const env = require('../../config/env');

class StaffService {
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
                    error.messageToShow = 'You do not have permission to manage staff for this business.';
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
            error.messageToShow = 'Please select or create an active business before adding staff members.';
            throw error;
        }

        return activeBusiness;
    }

    /**
     * Helper to safely remove local staff avatar file
     */
    _removeLocalAvatar(avatarUrl) {
        if (!avatarUrl || !avatarUrl.startsWith(`/${env.uploadDir}/avatars/`)) return;

        try {
            const fileName = path.basename(avatarUrl);
            const fullPath = path.join(__dirname, '..', '..', env.uploadDir, 'avatars', fileName);
            if (fs.existsSync(fullPath)) {
                fs.unlinkSync(fullPath);
            }
        } catch (err) {
            console.error('Failed to delete old staff avatar file:', err.message);
        }
    }

    /**
     * Helper to sync assigned services in staff_services table
     */
    async _syncStaffServices(staffId, serviceIds, transaction) {
        if (!Array.isArray(serviceIds)) return;

        await StaffServiceModel.destroy({
            where: { staff_id: staffId },
            transaction,
        });

        if (serviceIds.length > 0) {
            const uniqueIds = [...new Set(serviceIds.filter(Boolean))];
            const records = uniqueIds.map((serviceId) => ({
                staff_id: staffId,
                service_id: serviceId,
            }));
            await StaffServiceModel.bulkCreate(records, { transaction });
        }
    }

    /**
     * Helper to sync operating hours & breaks in staff_operating_hours
     */
    async _syncStaffSchedule(staffId, scheduleMap, transaction) {
        if (!scheduleMap || typeof scheduleMap !== 'object') return;

        // Fetch existing hours to delete cascading breaks
        const existingHours = await StaffOperatingHour.findAll({
            where: { staff_id: staffId },
            attributes: ['id'],
            transaction,
        });

        if (existingHours.length > 0) {
            const hourIds = existingHours.map((h) => h.id);
            await StaffScheduleBreak.destroy({
                where: { staff_operating_hour_id: { [Op.in]: hourIds } },
                transaction,
            });
            await StaffOperatingHour.destroy({
                where: { staff_id: staffId },
                transaction,
            });
        }

        for (const [dayKey, dayData] of Object.entries(scheduleMap)) {
            const dayOfWeek = parseInt(dayKey, 10);
            if (isNaN(dayOfWeek) || dayOfWeek < 1 || dayOfWeek > 7) continue;

            const isOpen = dayData.isOpen === true || dayData.is_working === true || dayData.isOpen === 'true';
            const startTime = dayData.openTime || dayData.start_time || '09:00:00';
            const closeTime = dayData.closeTime || dayData.close_time || '18:00:00';

            const hourRecord = await StaffOperatingHour.create(
                {
                    staff_id: staffId,
                    day_of_week: dayOfWeek,
                    is_working: isOpen,
                    start_time: startTime.length === 5 ? `${startTime}:00` : startTime,
                    close_time: closeTime.length === 5 ? `${closeTime}:00` : closeTime,
                },
                { transaction }
            );

            if (isOpen && Array.isArray(dayData.breaks) && dayData.breaks.length > 0) {
                const breakRecords = dayData.breaks.map((b) => {
                    const bStart = b.startTime || b.start_time || '13:00:00';
                    const bEnd = b.endTime || b.end_time || '14:00:00';
                    return {
                        staff_operating_hour_id: hourRecord.id,
                        break_name: b.breakName || b.break_name || 'Break',
                        start_time: bStart.length === 5 ? `${bStart}:00` : bStart,
                        end_time: bEnd.length === 5 ? `${bEnd}:00` : bEnd,
                    };
                });
                await StaffScheduleBreak.bulkCreate(breakRecords, { transaction });
            }
        }
    }

    /**
     * Create a new staff member
     */
    async createStaff(ownerId, data, avatarFile) {
        const business = await this._resolveBusiness(ownerId, data.businessId || data.business_id);

        let serviceIds = data.assignedServiceIds;
        if (typeof serviceIds === 'string') {
            try {
                serviceIds = JSON.parse(serviceIds);
            } catch (_) {
                serviceIds = serviceIds.split(',').map((s) => s.trim());
            }
        }

        let schedule = data.schedule;
        if (typeof schedule === 'string') {
            try {
                schedule = JSON.parse(schedule);
            } catch (_) {
                schedule = null;
            }
        }

        const name = data.name.trim();
        const email = (data.email && data.email.trim()) ? data.email.trim().toLowerCase() : null;
        const phone = (data.phone && data.phone.trim()) ? data.phone.trim() : null;
        const user_id = data.userId || data.user_id || null;
        const is_active = data.isActive !== undefined ? Boolean(data.isActive) : (data.is_active !== undefined ? Boolean(data.is_active) : true);
        const avatar_url = avatarFile ? `/${env.uploadDir}/avatars/${avatarFile.filename}` : null;

        const transaction = await sequelize.transaction();
        try {
            const newStaff = await Staff.create(
                {
                    business_id: business.id,
                    user_id,
                    name,
                    email,
                    phone,
                    avatar_url,
                    is_active,
                },
                { transaction }
            );

            if (Array.isArray(serviceIds) && serviceIds.length > 0) {
                await this._syncStaffServices(newStaff.id, serviceIds, transaction);
            }

            if (schedule) {
                await this._syncStaffSchedule(newStaff.id, schedule, transaction);
            }

            await transaction.commit();

            const fullStaff = await Staff.findByPk(newStaff.id, {
                include: [
                    {
                        model: Service,
                        as: 'services',
                        attributes: ['id', 'name', 'price', 'duration_minutes'],
                        through: { attributes: [] },
                    },
                    {
                        model: StaffOperatingHour,
                        as: 'operatingHours',
                        include: [{ model: StaffScheduleBreak, as: 'breaks' }],
                    },
                ],
            });

            return {
                staff: fullStaff.toClientJSON(),
                messageToShow: `"${newStaff.name}" has been added to your staff team.`,
            };
        } catch (error) {
            await transaction.rollback();
            if (avatarFile) this._removeLocalAvatar(`/${env.uploadDir}/avatars/${avatarFile.filename}`);
            throw error;
        }
    }

    /**
     * Get all staff for owner's business
     */
    async getStaff(ownerId, query = {}) {
        const requestedBusinessId = query.businessId || query.business_id;
        const whereClause = {};

        if (requestedBusinessId) {
            const business = await this._resolveBusiness(ownerId, requestedBusinessId);
            whereClause.business_id = business.id;
        } else {
            const userBusinesses = await Business.findAll({
                where: { owner_id: ownerId },
                attributes: ['id'],
            });
            const businessIds = userBusinesses.map((b) => b.id);
            whereClause.business_id = { [Op.in]: businessIds };
        }

        if (query.isActive !== undefined || query.is_active !== undefined) {
            const activeFilter = query.isActive !== undefined ? query.isActive : query.is_active;
            whereClause.is_active = activeFilter === true || activeFilter === 'true';
        }

        const include = [
            {
                model: Service,
                as: 'services',
                attributes: ['id', 'name', 'price', 'duration_minutes'],
                through: { attributes: [] },
                required: false,
            },
            {
                model: StaffOperatingHour,
                as: 'operatingHours',
                include: [{ model: StaffScheduleBreak, as: 'breaks' }],
                required: false,
            },
            {
                model: Business,
                as: 'business',
                attributes: ['id', 'name'],
            },
        ];

        // Filter by assigned service if requested
        const filterServiceId = query.serviceId || query.service_id;
        if (filterServiceId) {
            include[0].where = { id: filterServiceId };
            include[0].required = true;
        }

        const staffList = await Staff.findAll({
            where: whereClause,
            order: [
                ['is_active', 'DESC'],
                ['name', 'ASC'],
            ],
            include,
        });

        return {
            staff: staffList.map((s) => s.toClientJSON()),
            total: staffList.length,
            messageToShow: staffList.length > 0
                ? 'Staff team retrieved successfully.'
                : 'No staff members found. You can add your first staff member to get started.',
        };
    }

    /**
     * Get single staff member by ID
     */
    async getStaffById(ownerId, staffId) {
        const staff = await Staff.findByPk(staffId, {
            include: [
                {
                    model: Service,
                    as: 'services',
                    attributes: ['id', 'name', 'price', 'duration_minutes'],
                    through: { attributes: [] },
                },
                {
                    model: StaffOperatingHour,
                    as: 'operatingHours',
                    include: [{ model: StaffScheduleBreak, as: 'breaks' }],
                },
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!staff) {
            const error = new Error('Staff member not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested staff member could not be found.';
            throw error;
        }

        // Verify permission
        if (staff.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: staff.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized staff access.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to view this staff member.';
                throw error;
            }
        }

        return {
            staff: staff.toClientJSON(),
            messageToShow: 'Staff details retrieved successfully.',
        };
    }

    /**
     * Public lookup by business booking link slug (for customer online booking)
     */
    async getPublicStaffBySlug(businessSlug, query = {}) {
        const cleanSlug = businessSlug.trim().toLowerCase();

        const business = await Business.findOne({
            where: { slug: cleanSlug },
            attributes: ['id', 'name', 'slug', 'is_active'],
        });

        if (!business) {
            const error = new Error('Business not found with this booking link.');
            error.statusCode = 404;
            error.messageToShow = 'No business was found with this booking link.';
            throw error;
        }

        const include = [
            {
                model: Service,
                as: 'services',
                attributes: ['id', 'name', 'price', 'duration_minutes'],
                through: { attributes: [] },
                required: false,
            },
            {
                model: StaffOperatingHour,
                as: 'operatingHours',
                include: [{ model: StaffScheduleBreak, as: 'breaks' }],
                required: false,
            },
        ];

        // Filter by service if customer selected a specific service
        const filterServiceId = query.serviceId || query.service_id;
        if (filterServiceId) {
            include[0].where = { id: filterServiceId };
            include[0].required = true;
        }

        const staffList = await Staff.findAll({
            where: {
                business_id: business.id,
                is_active: true,
            },
            order: [['name', 'ASC']],
            include,
        });

        return {
            business: business.toClientJSON(),
            staff: staffList.map((s) => s.toClientJSON()),
            total: staffList.length,
            messageToShow: 'Staff list loaded successfully.',
        };
    }

    /**
     * Update an existing staff member
     */
    async updateStaff(ownerId, staffId, data, avatarFile) {
        const staff = await Staff.findByPk(staffId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!staff) {
            if (avatarFile) this._removeLocalAvatar(`/${env.uploadDir}/avatars/${avatarFile.filename}`);
            const error = new Error('Staff member not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested staff member could not be found.';
            throw error;
        }

        if (staff.business?.owner_id !== ownerId) {
            if (avatarFile) this._removeLocalAvatar(`/${env.uploadDir}/avatars/${avatarFile.filename}`);
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to modify this staff member.';
            throw error;
        }

        let serviceIds = data.assignedServiceIds;
        if (typeof serviceIds === 'string') {
            try {
                serviceIds = JSON.parse(serviceIds);
            } catch (_) {
                serviceIds = serviceIds.split(',').map((s) => s.trim());
            }
        }

        let schedule = data.schedule;
        if (typeof schedule === 'string') {
            try {
                schedule = JSON.parse(schedule);
            } catch (_) {
                schedule = null;
            }
        }

        const updateData = {};
        if (data.name !== undefined && data.name.trim() !== '') updateData.name = data.name.trim();
        if (data.email !== undefined) updateData.email = data.email ? data.email.trim().toLowerCase() : null;
        if (data.phone !== undefined) updateData.phone = data.phone ? data.phone.trim() : null;
        if (data.userId !== undefined || data.user_id !== undefined) updateData.user_id = data.userId || data.user_id || null;
        if (data.isActive !== undefined || data.is_active !== undefined) {
            const activeVal = data.isActive !== undefined ? data.isActive : data.is_active;
            updateData.is_active = activeVal === true || activeVal === 'true';
        }

        if (avatarFile) {
            if (staff.avatar_url) this._removeLocalAvatar(staff.avatar_url);
            updateData.avatar_url = `/${env.uploadDir}/avatars/${avatarFile.filename}`;
        }

        const transaction = await sequelize.transaction();
        try {
            await staff.update(updateData, { transaction });

            if (serviceIds !== undefined) {
                await this._syncStaffServices(staff.id, serviceIds, transaction);
            }

            if (schedule !== undefined && schedule !== null) {
                await this._syncStaffSchedule(staff.id, schedule, transaction);
            }

            await transaction.commit();

            const updatedStaff = await Staff.findByPk(staff.id, {
                include: [
                    {
                        model: Service,
                        as: 'services',
                        attributes: ['id', 'name', 'price', 'duration_minutes'],
                        through: { attributes: [] },
                    },
                    {
                        model: StaffOperatingHour,
                        as: 'operatingHours',
                        include: [{ model: StaffScheduleBreak, as: 'breaks' }],
                    },
                ],
            });

            return {
                staff: updatedStaff.toClientJSON(),
                messageToShow: `"${updatedStaff.name}" details updated successfully.`,
            };
        } catch (error) {
            await transaction.rollback();
            if (avatarFile) this._removeLocalAvatar(`/${env.uploadDir}/avatars/${avatarFile.filename}`);
            throw error;
        }
    }

    /**
     * Toggle active/inactive status
     */
    async toggleStaffStatus(ownerId, staffId) {
        const staff = await Staff.findByPk(staffId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!staff) {
            const error = new Error('Staff member not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested staff member could not be found.';
            throw error;
        }

        if (staff.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to modify this staff member.';
            throw error;
        }

        const newStatus = !staff.is_active;
        await staff.update({ is_active: newStatus });

        return {
            staff: staff.toClientJSON(),
            messageToShow: `"${staff.name}" is now ${newStatus ? 'active' : 'inactive'}.`,
        };
    }

    /**
     * Delete staff member
     */
    async deleteStaff(ownerId, staffId) {
        const staff = await Staff.findByPk(staffId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!staff) {
            const error = new Error('Staff member not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested staff member could not be found.';
            throw error;
        }

        if (staff.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to delete this staff member.';
            throw error;
        }

        const staffName = staff.name;
        const avatarUrl = staff.avatar_url;

        await staff.destroy();

        if (avatarUrl) {
            this._removeLocalAvatar(avatarUrl);
        }

        return {
            deletedId: staffId,
            messageToShow: `"${staffName}" has been removed from your staff team successfully.`,
        };
    }
}

module.exports = new StaffService();

const { Op } = require('sequelize');
const { sequelize } = require('../../config/database');
const { Booking, BookingReschedule, Payment, Customer } = require('./index');
const { Business, BusinessMember } = require('../businesses');
const { Service } = require('../services');
const { Staff } = require('../staff');

class BookingService {
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
                    error.messageToShow = 'You do not have permission to manage bookings for this business.';
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
            error.messageToShow = 'Please select or create an active business before creating or viewing appointments.';
            throw error;
        }

        return activeBusiness;
    }

    /**
     * Helper to generate a unique human-friendly booking reference (e.g. AP-849201)
     */
    async _generateBookingReference() {
        let isUnique = false;
        let reference = '';
        let attempts = 0;

        while (!isUnique && attempts < 10) {
            attempts++;
            const randomCode = Math.floor(100000 + Math.random() * 900000);
            reference = `AP-${randomCode}`;

            const existing = await Booking.findOne({ where: { booking_reference: reference } });
            if (!existing) {
                isUnique = true;
            }
        }

        if (!isUnique) {
            reference = `AP-${Date.now().toString().slice(-6)}`;
        }

        return reference;
    }

    /**
     * Helper to find a booking by either UUID or human-friendly booking_reference (e.g. AP-849201)
     */
    async _findBookingByIdOrRef(bookingId, options = {}) {
        if (!bookingId) return null;
        const trimmed = String(bookingId).trim();
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(trimmed);

        if (isUUID) {
            const byPk = await Booking.findByPk(trimmed, options);
            if (byPk) return byPk;
        }

        return await Booking.findOne({
            where: { booking_reference: trimmed },
            ...options,
        });
    }

    /**
     * Create an appointment booking (works for authenticated owner or public booking link)
     */
    async createBooking({ ownerId = null, businessSlug = null, data }) {
        let business;

        if (businessSlug) {
            business = await Business.findOne({
                where: { slug: businessSlug.trim().toLowerCase() },
            });
            if (!business) {
                const error = new Error('Business not found.');
                error.statusCode = 404;
                error.messageToShow = 'No business was found with this booking link.';
                throw error;
            }
        } else {
            business = await this._resolveBusiness(ownerId, data.businessId || data.business_id);
        }

        // Validate service
        const serviceId = data.serviceId || data.service_id;
        const service = await Service.findOne({
            where: {
                id: serviceId,
                business_id: business.id,
            },
        });

        if (!service) {
            const error = new Error('Service not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested service is not offered by this business.';
            throw error;
        }

        if (!service.is_active) {
            const error = new Error('Service inactive.');
            error.statusCode = 400;
            error.messageToShow = 'This service is currently unavailable for booking.';
            throw error;
        }

        // Validate staff if assigned
        let staff = null;
        const staffId = data.staffId || data.staff_id;
        if (staffId) {
            staff = await Staff.findOne({
                where: {
                    id: staffId,
                    business_id: business.id,
                },
            });

            if (!staff) {
                const error = new Error('Staff member not found.');
                error.statusCode = 404;
                error.messageToShow = 'The selected staff member could not be found.';
                throw error;
            }
        }

        const customerName = data.customerName.trim();
        const customerCountryCode = data.customerCountryCode || data.customer_country_code || '+91';
        const customerPhone = (data.customerPhone || data.customer_phone).trim();
        const customerEmail = data.customerEmail || data.customer_email ? (data.customerEmail || data.customer_email).trim().toLowerCase() : null;
        const customerNotes = data.customerNotes || data.customer_notes ? (data.customerNotes || data.customer_notes).trim() : null;

        const startAt = new Date(data.startAt || data.start_at);
        const durationMs = (service.duration_minutes || 30) * 60000;
        const endAt = (data.endAt || data.end_at)
            ? new Date(data.endAt || data.end_at)
            : new Date(startAt.getTime() + durationMs);

        const price = data.price !== undefined ? parseFloat(data.price) : parseFloat(service.price);

        const transaction = await sequelize.transaction();
        try {
            // CRM Ledger: Auto upsert customer
            let [customer] = await Customer.findOrCreate({
                where: {
                    business_id: business.id,
                    phone: customerPhone,
                },
                defaults: {
                    business_id: business.id,
                    name: customerName,
                    country_code: customerCountryCode,
                    phone: customerPhone,
                    email: customerEmail,
                    notes: customerNotes,
                },
                transaction,
            });

            if (customer.name !== customerName || (customerEmail && customer.email !== customerEmail)) {
                await customer.update({
                    name: customerName,
                    email: customerEmail || customer.email,
                }, { transaction });
            }

            const bookingReference = await this._generateBookingReference();

            const newBooking = await Booking.create({
                booking_reference: bookingReference,
                business_id: business.id,
                service_id: service.id,
                staff_id: staff ? staff.id : null,
                customer_id: customer.id,
                service_name: service.name,
                staff_name: staff ? staff.name : null,
                customer_name: customerName,
                customer_country_code: customerCountryCode,
                customer_phone: customerPhone,
                customer_email: customerEmail,
                customer_notes: customerNotes,
                start_at: startAt,
                end_at: endAt,
                price,
                status: 'confirmed',
            }, { transaction });

            await transaction.commit();

            const fullBooking = await Booking.findByPk(newBooking.id, {
                include: [
                    { model: Service, as: 'service', attributes: ['id', 'name', 'price', 'duration_minutes'] },
                    { model: Staff, as: 'staff', attributes: ['id', 'name', 'phone', 'avatar_url'] },
                    { model: Customer, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] },
                    { model: BookingReschedule, as: 'rescheduleHistory' },
                    { model: Payment, as: 'payments' },
                ],
            });

            return {
                booking: fullBooking.toClientJSON(),
                messageToShow: `Appointment confirmed successfully! Your booking reference is ${bookingReference}.`,
            };
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }

    /**
     * Get all bookings for business with filters
     */
    async getBookings(ownerId, query = {}) {
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

        // Status filter
        if (query.status && query.status.trim()) {
            whereClause.status = query.status.trim();
        }

        // Staff filter
        const staffId = query.staffId || query.staff_id;
        if (staffId && staffId.trim()) {
            whereClause.staff_id = staffId.trim();
        }

        // Customer filter
        const customerId = query.customerId || query.customer_id;
        if (customerId && customerId.trim()) {
            whereClause.customer_id = customerId.trim();
        }

        // Date range filter
        const startDate = query.startDate || query.start_date;
        const endDate = query.endDate || query.end_date;
        if (startDate && endDate) {
            whereClause.start_at = {
                [Op.between]: [new Date(startDate), new Date(endDate)],
            };
        } else if (startDate) {
            whereClause.start_at = {
                [Op.gte]: new Date(startDate),
            };
        }

        // Search keyword
        if (query.search && query.search.trim()) {
            const keyword = `%${query.search.trim()}%`;
            whereClause[Op.or] = [
                { booking_reference: { [Op.iLike || Op.like]: keyword } },
                { customer_name: { [Op.iLike || Op.like]: keyword } },
                { customer_phone: { [Op.iLike || Op.like]: keyword } },
                { service_name: { [Op.iLike || Op.like]: keyword } },
            ];
        }

        const bookings = await Booking.findAll({
            where: whereClause,
            order: [['start_at', 'DESC']],
            include: [
                { model: Service, as: 'service', attributes: ['id', 'name', 'price', 'duration_minutes'] },
                { model: Staff, as: 'staff', attributes: ['id', 'name', 'avatar_url'] },
                { model: Customer, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] },
                { model: BookingReschedule, as: 'rescheduleHistory' },
                { model: Payment, as: 'payments' },
            ],
        });

        return {
            bookings: bookings.map((b) => b.toClientJSON()),
            total: bookings.length,
            messageToShow: bookings.length > 0
                ? 'Bookings retrieved successfully.'
                : 'No appointments found matching your filter criteria.',
        };
    }

    /**
     * Get single booking by ID
     */
    async getBookingById(ownerId, bookingId) {
        const booking = await this._findBookingByIdOrRef(bookingId, {
            include: [
                { model: Business, as: 'business', attributes: ['id', 'owner_id', 'name', 'currency'] },
                { model: Service, as: 'service', attributes: ['id', 'name', 'price', 'duration_minutes'] },
                { model: Staff, as: 'staff', attributes: ['id', 'name', 'phone', 'avatar_url'] },
                { model: Customer, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] },
                { model: BookingReschedule, as: 'rescheduleHistory' },
                { model: Payment, as: 'payments' },
            ],
        });

        if (!booking) {
            const error = new Error('Booking not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested appointment could not be found.';
            throw error;
        }

        if (booking.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: booking.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to view this booking.';
                throw error;
            }
        }

        return {
            booking: booking.toClientJSON(),
            messageToShow: 'Booking details retrieved successfully.',
        };
    }

    /**
     * Public lookup by booking reference code
     */
    async getBookingByReference(bookingReference) {
        const booking = await this._findBookingByIdOrRef(bookingReference, {
            include: [
                { model: Business, as: 'business', attributes: ['id', 'name', 'slug', 'currency', 'phone'] },
                { model: Service, as: 'service', attributes: ['id', 'name', 'price', 'duration_minutes'] },
                { model: Staff, as: 'staff', attributes: ['id', 'name', 'avatar_url'] },
                { model: BookingReschedule, as: 'rescheduleHistory' },
                { model: Payment, as: 'payments' },
            ],
        });

        if (!booking) {
            const error = new Error('Booking reference not found.');
            error.statusCode = 404;
            error.messageToShow = 'No appointment found with this booking reference. Please double-check your code.';
            throw error;
        }

        return {
            booking: booking.toClientJSON(),
            messageToShow: 'Appointment details loaded successfully.',
        };
    }

    /**
     * Update booking status (confirmed, completed, cancelled, noShow)
     */
    async updateBookingStatus(ownerId, bookingId, { status, cancellationReason }) {
        const booking = await this._findBookingByIdOrRef(bookingId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!booking) {
            const error = new Error('Booking not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested appointment could not be found.';
            throw error;
        }

        if (ownerId && booking.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: booking.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to update this booking.';
                throw error;
            }
        }

        const updateData = { status };
        if (status === 'cancelled') {
            updateData.cancelled_at = new Date();
            updateData.cancellation_reason = cancellationReason || 'Cancelled by business.';
        }

        await booking.update(updateData);

        const statusLabels = {
            confirmed: 'Confirmed',
            completed: 'Marked as Completed',
            cancelled: 'Cancelled',
            noShow: 'Marked as No-Show',
        };

        return {
            booking: booking.toClientJSON(),
            messageToShow: `Appointment status updated to "${statusLabels[status] || status}".`,
        };
    }

    /**
     * Reschedule appointment (updates start/end times and records audit history)
     */
    async rescheduleBooking(ownerId, bookingId, data) {
        const booking = await this._findBookingByIdOrRef(bookingId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!booking) {
            const error = new Error('Booking not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested appointment could not be found.';
            throw error;
        }

        if (ownerId && booking.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to reschedule this appointment.';
            throw error;
        }

        const previousStartAt = booking.start_at;
        const previousEndAt = booking.end_at;
        const previousStaffId = booking.staff_id;

        const durationMs = new Date(previousEndAt).getTime() - new Date(previousStartAt).getTime();
        const newStartAt = new Date(data.newStartAt || data.new_start_at);
        const newEndAt = (data.newEndAt || data.new_end_at)
            ? new Date(data.newEndAt || data.new_end_at)
            : new Date(newStartAt.getTime() + durationMs);

        const newStaffId = data.newStaffId || data.new_staff_id || booking.staff_id;
        const reason = data.reason || null;

        // If staff changed, resolve staff name
        let staffName = booking.staff_name;
        if (newStaffId && newStaffId !== previousStaffId) {
            const newStaff = await Staff.findByPk(newStaffId);
            if (newStaff) staffName = newStaff.name;
        }

        const transaction = await sequelize.transaction();
        try {
            await BookingReschedule.create({
                booking_id: booking.id,
                previous_start_at: previousStartAt,
                previous_end_at: previousEndAt,
                new_start_at: newStartAt,
                new_end_at: newEndAt,
                previous_staff_id: previousStaffId,
                new_staff_id: newStaffId,
                reason,
            }, { transaction });

            await booking.update({
                start_at: newStartAt,
                end_at: newEndAt,
                staff_id: newStaffId,
                staff_name: staffName,
                status: 'confirmed',
            }, { transaction });

            await transaction.commit();

            const updatedBooking = await Booking.findByPk(booking.id, {
                include: [
                    { model: Service, as: 'service' },
                    { model: Staff, as: 'staff' },
                    { model: Customer, as: 'customer' },
                    { model: BookingReschedule, as: 'rescheduleHistory' },
                    { model: Payment, as: 'payments' },
                ],
            });

            return {
                booking: updatedBooking.toClientJSON(),
                messageToShow: 'Appointment rescheduled successfully.',
            };
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }

    /**
     * Delete booking
     */
    async deleteBooking(ownerId, bookingId) {
        const booking = await this._findBookingByIdOrRef(bookingId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!booking) {
            const error = new Error('Booking not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested appointment could not be found.';
            throw error;
        }

        if (booking.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to delete this booking.';
            throw error;
        }

        const ref = booking.booking_reference;
        await booking.destroy();

        return {
            deletedId: bookingId,
            messageToShow: `Appointment ${ref} has been deleted successfully.`,
        };
    }
}

module.exports = new BookingService();

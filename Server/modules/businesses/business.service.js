const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { sequelize } = require('../../config/database');
const { Business, BusinessMember } = require('./index');
const env = require('../../config/env');

class BusinessService {
    /**
     * Helper to generate a unique, clean, SEO-friendly slug
     */
    async _generateUniqueSlug(name) {
        const baseSlug = name
            .toString()
            .toLowerCase()
            .trim()
            .replace(/[^\w\s-]/g, '') // remove non-word chars
            .replace(/[\s_-]+/g, '-') // collapse whitespace and underscores to -
            .replace(/^-+|-+$/g, '') || 'business';

        let slug = '';
        let isUnique = false;
        let attempts = 0;

        while (!isUnique && attempts < 10) {
            attempts++;
            const randomSuffix = Math.floor(1000 + Math.random() * 9000);
            slug = `${baseSlug}-${randomSuffix}`;

            const existing = await Business.findOne({ where: { slug } });
            if (!existing) {
                isUnique = true;
            }
        }

        if (!isUnique) {
            slug = `${baseSlug}-${Date.now()}`;
        }

        return slug;
    }

    /**
     * Helper to safely remove local logo file
     */
    _removeLocalLogo(logoUrl) {
        if (!logoUrl || !logoUrl.startsWith(`/${env.uploadDir}/logos/`)) return;

        try {
            const fileName = path.basename(logoUrl);
            const fullPath = path.join(__dirname, '..', '..', env.uploadDir, 'logos', fileName);
            if (fs.existsSync(fullPath)) {
                fs.unlinkSync(fullPath);
            }
        } catch (err) {
            console.error('Failed to delete old logo file:', err.message);
        }
    }

    /**
     * Create a new business
     */
    async createBusiness(ownerId, data, logoFile) {
        const transaction = await sequelize.transaction();

        try {
            const name = data.name.trim();
            const type = data.type.trim();
            const other_type = data.otherType || data.other_type || null;
            const email = (data.email && data.email.trim()) ? data.email.trim().toLowerCase() : null;
            const country_code = data.countryCode || data.country_code || '+91';
            const phone = (data.phone && data.phone.trim()) ? data.phone.trim() : null;
            const currency = data.currency || 'INR';
            const timezone = data.timezone || 'Asia/Kolkata';

            // Check if this is the owner's first business
            const existingCount = await Business.count({
                where: { owner_id: ownerId },
                transaction,
            });

            // Domain rule: If it's the owner's first business, automatically set is_active = true.
            // If explicitly specified as active, deactivate previous businesses.
            let is_active = false;
            const requestedActive = data.isActive === true || data.is_active === true || data.isActive === 'true' || data.is_active === 'true';

            if (existingCount === 0 || requestedActive) {
                is_active = true;
                if (existingCount > 0) {
                    await Business.update(
                        { is_active: false },
                        { where: { owner_id: ownerId }, transaction }
                    );
                }
            }

            const slug = await this._generateUniqueSlug(name);
            const logo_url = logoFile ? `/${env.uploadDir}/logos/${logoFile.filename}` : null;

            const newBusiness = await Business.create(
                {
                    owner_id: ownerId,
                    name,
                    slug,
                    type,
                    other_type,
                    logo_url,
                    email,
                    country_code,
                    phone,
                    currency,
                    timezone,
                    is_active,
                },
                { transaction }
            );

            // Record owner as member in business_members table
            await BusinessMember.create(
                {
                    business_id: newBusiness.id,
                    user_id: ownerId,
                    role: 'owner',
                    is_active: true,
                },
                { transaction }
            );

            await transaction.commit();

            return {
                business: newBusiness.toClientJSON(),
                messageToShow: `"${newBusiness.name}" has been registered successfully.`,
            };
        } catch (error) {
            await transaction.rollback();
            if (logoFile) this._removeLocalLogo(`/${env.uploadDir}/logos/${logoFile.filename}`);
            throw error;
        }
    }

    /**
     * Get all businesses owned by user (sorted with active business first)
     */
    async getBusinesses(ownerId) {
        const businesses = await Business.findAll({
            where: { owner_id: ownerId },
            order: [
                ['is_active', 'DESC'],
                ['created_at', 'DESC'],
            ],
        });

        return {
            businesses: businesses.map((b) => b.toClientJSON()),
            total: businesses.length,
            messageToShow: businesses.length > 0
                ? 'Businesses retrieved successfully.'
                : 'No businesses found. You can add your first business to get started.',
        };
    }

    /**
     * Get single business by ID (must belong to owner)
     */
    async getBusinessById(ownerId, businessId) {
        const business = await Business.findOne({
            where: {
                id: businessId,
                owner_id: ownerId,
            },
        });

        if (!business) {
            const error = new Error('Business not found or you do not have permission to view it.');
            error.statusCode = 404;
            error.messageToShow = 'The requested business could not be found or you do not have permission to view it.';
            throw error;
        }

        return {
            business: business.toClientJSON(),
            messageToShow: 'Business details retrieved successfully.',
        };
    }

    /**
     * Public lookup by slug (for customer online booking)
     */
    async getPublicBusinessBySlug(slug) {
        const cleanSlug = slug.trim().toLowerCase();
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(slug.trim());

        const business = await Business.findOne({
            where: isUUID
                ? { [Op.or]: [{ id: slug.trim() }, { slug: cleanSlug }] }
                : { slug: cleanSlug },
            attributes: [
                'id',
                'name',
                'slug',
                'type',
                'other_type',
                'logo_url',
                'email',
                'country_code',
                'phone',
                'currency',
                'timezone',
                'is_active',
                'created_at',
            ],
        });

        if (!business) {
            const error = new Error('No business found for this booking link.');
            error.statusCode = 404;
            error.messageToShow = 'No business was found with this booking link. Please verify the URL and try again.';
            throw error;
        }

        return {
            business: business.toClientJSON(),
            messageToShow: 'Business details loaded successfully.',
        };
    }

    /**
     * Update an existing business
     */
    async updateBusiness(ownerId, businessId, data, logoFile) {
        const business = await Business.findOne({
            where: {
                id: businessId,
                owner_id: ownerId,
            },
        });

        if (!business) {
            if (logoFile) this._removeLocalLogo(`/${env.uploadDir}/logos/${logoFile.filename}`);
            const error = new Error('Business not found or you do not have permission to modify it.');
            error.statusCode = 404;
            error.messageToShow = 'The business could not be found or you do not have permission to update it.';
            throw error;
        }

        const updateData = {};

        if (data.name !== undefined && data.name.trim() !== '') {
            updateData.name = data.name.trim();
        }
        if (data.type !== undefined && data.type.trim() !== '') {
            updateData.type = data.type.trim();
        }
        if (data.otherType !== undefined || data.other_type !== undefined) {
            updateData.other_type = data.otherType || data.other_type || null;
        }
        if (data.email !== undefined) {
            updateData.email = data.email ? data.email.trim().toLowerCase() : null;
        }
        if (data.countryCode !== undefined || data.country_code !== undefined) {
            updateData.country_code = data.countryCode || data.country_code;
        }
        if (data.phone !== undefined) {
            updateData.phone = data.phone ? data.phone.trim() : null;
        }
        if (data.currency !== undefined && data.currency.trim() !== '') {
            updateData.currency = data.currency.trim();
        }
        if (data.timezone !== undefined && data.timezone.trim() !== '') {
            updateData.timezone = data.timezone.trim();
        }

        // Handle logo replacement
        if (logoFile) {
            if (business.logo_url) {
                this._removeLocalLogo(business.logo_url);
            }
            updateData.logo_url = `/${env.uploadDir}/logos/${logoFile.filename}`;
        }

        // Active state update
        const wantsActive = data.isActive === true || data.is_active === true || data.isActive === 'true' || data.is_active === 'true';
        const wantsDeactive = data.isActive === false || data.is_active === false || data.isActive === 'false' || data.is_active === 'false';

        const transaction = await sequelize.transaction();
        try {
            if (wantsActive) {
                // Deactivate all other businesses for this owner
                await Business.update(
                    { is_active: false },
                    {
                        where: {
                            owner_id: ownerId,
                            id: { [Op.ne]: businessId },
                        },
                        transaction,
                    }
                );
                updateData.is_active = true;
            } else if (wantsDeactive) {
                updateData.is_active = false;
            }

            await business.update(updateData, { transaction });
            await transaction.commit();

            return {
                business: business.toClientJSON(),
                messageToShow: `"${business.name}" details updated successfully.`,
            };
        } catch (error) {
            await transaction.rollback();
            if (logoFile) this._removeLocalLogo(`/${env.uploadDir}/logos/${logoFile.filename}`);
            throw error;
        }
    }

    /**
     * Switch active business
     */
    async setActiveBusiness(ownerId, businessId) {
        const business = await Business.findOne({
            where: {
                id: businessId,
                owner_id: ownerId,
            },
        });

        if (!business) {
            const error = new Error('Business not found or you do not have permission to activate it.');
            error.statusCode = 404;
            error.messageToShow = 'The business could not be found or you do not have permission to activate it.';
            throw error;
        }

        const transaction = await sequelize.transaction();
        try {
            // Deactivate all businesses of this owner
            await Business.update(
                { is_active: false },
                { where: { owner_id: ownerId }, transaction }
            );

            // Activate target business
            await business.update({ is_active: true }, { transaction });

            await transaction.commit();

            return {
                business: business.toClientJSON(),
                messageToShow: `"${business.name}" is now set as your active business.`,
            };
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }

    /**
     * Delete business (with fallback active selection and logo cleanup)
     */
    async deleteBusiness(ownerId, businessId) {
        const business = await Business.findOne({
            where: {
                id: businessId,
                owner_id: ownerId,
            },
        });

        if (!business) {
            const error = new Error('Business not found or you do not have permission to delete it.');
            error.statusCode = 404;
            error.messageToShow = 'The business could not be found or you do not have permission to delete it.';
            throw error;
        }

        const wasActive = business.is_active;
        const businessName = business.name;
        const logoUrl = business.logo_url;

        const transaction = await sequelize.transaction();
        try {
            await business.destroy({ transaction });

            let newActiveBusiness = null;
            if (wasActive) {
                // Find next most recent business owned by this user to make active
                const fallback = await Business.findOne({
                    where: { owner_id: ownerId },
                    order: [['created_at', 'DESC']],
                    transaction,
                });

                if (fallback) {
                    await fallback.update({ is_active: true }, { transaction });
                    newActiveBusiness = fallback.toClientJSON();
                }
            }

            await transaction.commit();

            // Clean up logo file after successful deletion
            if (logoUrl) {
                this._removeLocalLogo(logoUrl);
            }

            return {
                deletedId: businessId,
                newActiveBusiness,
                messageToShow: `"${businessName}" has been deleted successfully.`,
            };
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }
}

module.exports = new BusinessService();

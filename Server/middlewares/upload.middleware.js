const multer = require('multer');
const path = require('path');
const fs = require('fs');
const env = require('../config/env');

const avatarDir = path.join(__dirname, '..', env.uploadDir, 'avatars');
const logoDir = path.join(__dirname, '..', env.uploadDir, 'logos');

if (!fs.existsSync(avatarDir)) {
    fs.mkdirSync(avatarDir, { recursive: true });
}
if (!fs.existsSync(logoDir)) {
    fs.mkdirSync(logoDir, { recursive: true });
}

const fileFilter = (req, file, cb) => {
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
    if (allowedMimeTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid image format. Only JPEG, PNG, and WebP are allowed.'), false);
    }
};

const avatarStorage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, avatarDir),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        cb(null, `avatar-${uniqueSuffix}${ext}`);
    },
});

const logoStorage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, logoDir),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        cb(null, `logo-${uniqueSuffix}${ext}`);
    },
});

const uploadAvatar = multer({
    storage: avatarStorage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

const uploadBusinessLogo = multer({
    storage: logoStorage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

module.exports = {
    uploadAvatar,
    uploadBusinessLogo,
};

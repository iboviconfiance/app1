const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

// ─── Ensure upload directories exist ─────────────────────────────────────────
const BASE_UPLOAD_DIR = path.join(__dirname, '../../../../uploads');
const DIRS = ['courses', 'thumbnails', 'exams'];
DIRS.forEach((dir) => {
  const p = path.join(BASE_UPLOAD_DIR, dir);
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
});

// ─── MIME type whitelist ──────────────────────────────────────────────────────
const ALLOWED_MIME = {
  pdf: ['application/pdf'],
  video: ['video/mp4'],
  image: ['image/jpeg', 'image/png', 'image/webp'],
};

// ─── Storage factory ──────────────────────────────────────────────────────────
function createStorage(subdir) {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, path.join(BASE_UPLOAD_DIR, subdir));
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, `${subdir.replace('s', '')}-${uuidv4()}${ext}`);
    },
  });
}

// ─── File filter factory ──────────────────────────────────────────────────────
function createFileFilter(allowedTypes) {
  return (req, file, cb) => {
    const allowed = allowedTypes.flatMap((t) => ALLOWED_MIME[t] || []);
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new multer.MulterError(
          'LIMIT_UNEXPECTED_FILE',
          `Type de fichier non autorisé : ${file.mimetype}. Types acceptés : ${allowed.join(', ')}`
        )
      );
    }
  };
}

// ─── Middleware instances ─────────────────────────────────────────────────────

/** Upload d'un PDF de cours — max 10 Mo */
const uploadCoursePdf = multer({
  storage: createStorage('courses'),
  fileFilter: createFileFilter(['pdf']),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
}).single('file');

/** Upload d'une vidéo de cours — max 150 Mo */
const uploadCourseVideo = multer({
  storage: createStorage('courses'),
  fileFilter: createFileFilter(['video']),
  limits: { fileSize: 150 * 1024 * 1024 }, // 150 MB
}).single('file');

/** Upload d'une image miniature — max 5 Mo */
const uploadThumbnail = multer({
  storage: createStorage('thumbnails'),
  fileFilter: createFileFilter(['image']),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
}).single('file');

/** Upload d'un PDF d'examen/annale — max 10 Mo */
const uploadExamPdf = multer({
  storage: createStorage('exams'),
  fileFilter: createFileFilter(['pdf']),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
}).single('file');

/**
 * Middleware universel : sélectionne automatiquement la bonne instance multer
 * selon le champ query ?fileType=pdf|video|image|exam
 */
function uploadAny(req, res, next) {
  const fileType = req.query.fileType || req.body.fileType || 'pdf';

  const handlers = {
    pdf: uploadCoursePdf,
    video: uploadCourseVideo,
    image: uploadThumbnail,
    exam: uploadExamPdf,
  };

  const handler = handlers[fileType] || uploadCoursePdf;

  handler(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({
        success: false,
        message: `Erreur d'upload : ${err.message}`,
        code: err.code,
      });
    }
    if (err) {
      return res.status(400).json({ success: false, message: err.message });
    }
    next();
  });
}

module.exports = { uploadAny, uploadCoursePdf, uploadCourseVideo, uploadThumbnail, uploadExamPdf };

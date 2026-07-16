require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const nodemailer = require('nodemailer');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// ============================================
// EMAIL SETUP
// ============================================

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
    },
});

function generateVerificationToken() {
    return Math.random().toString(36).substring(2, 15) + 
           Math.random().toString(36).substring(2, 15);
}

async function sendVerificationEmail(email, name, token) {
    const verificationUrl = `http://localhost:5000/api/verify-email?token=${token}`;
    
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'AgriMarket - Verify Your Email',
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #2C3E50;">Welcome to AgriMarket, ${name}!</h2>
                <p>Thank you for registering. Please verify your email address to complete your registration.</p>
                <div style="margin: 30px 0;">
                    <a href="${verificationUrl}" style="background-color: #9B59B6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">Verify Email</a>
                </div>
                <p>Or copy this link: ${verificationUrl}</p>
                <p>This link will expire in 24 hours.</p>
                <hr>
                <p style="color: #666; font-size: 12px;">AgriMarket - Connecting Farmers to Buyers in Sierra Leone</p>
            </div>
        `,
    };
    
    await transporter.sendMail(mailOptions);
}

// ============================================
// POSTGRESQL CONNECTION
// ============================================

const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'agrimarket_db',
    password: process.env.DB_PASSWORD || '5tgb&UJM232$1',
    port: process.env.DB_PORT || 5432,
});

pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ Database connection error:', err.stack);
    } else {
        console.log('✅ Connected to PostgreSQL database');
        release();
    }
});

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'Access denied' });
    }
    
    jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });
        req.user = user;
        next();
    });
};

const isAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    next();
};

// ============================================
// FILE UPLOAD (Local)
// ============================================

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'product-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ============================================
// TEST ENDPOINT
// ============================================

app.get('/api/test', (req, res) => {
    res.json({ 
        message: "AgriMarket API is working!",
        timestamp: new Date().toLocaleString(),
        currency: "SLE"
    });
});

// ============================================
// REGISTER ENDPOINT (with email verification)
// ============================================

app.post('/api/register', async (req, res) => {
    try {
        const { name, phone, email, password, role, location } = req.body;
        
        const existingUser = await pool.query(
            'SELECT * FROM users WHERE email = $1 OR phone = $2',
            [email, phone]
        );
        
        if (existingUser.rows.length > 0) {
            return res.status(400).json({ error: 'User already exists' });
        }
        
        const passwordHash = await bcrypt.hash(password, 10);
        const verificationToken = generateVerificationToken();
        const tokenExpiry = new Date();
        tokenExpiry.setHours(tokenExpiry.getHours() + 24);
        
        const result = await pool.query(
            `INSERT INTO users (name, phone, email, password_hash, role, location, is_verified, verification_token, token_expiry) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
             RETURNING user_id, name, email, role`,
            [name, phone, email, passwordHash, role, location, false, verificationToken, tokenExpiry]
        );
        
        await sendVerificationEmail(email, name, verificationToken);
        
        res.status(201).json({ 
            success: true, 
            message: 'Registration successful. Please verify your email.'
        });
        
    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============================================
// VERIFY EMAIL ENDPOINT
// ============================================

app.get('/api/verify-email', async (req, res) => {
    try {
        const { token } = req.query;
        
        const result = await pool.query(
            'SELECT * FROM users WHERE verification_token = $1 AND token_expiry > NOW()',
            [token]
        );
        
        if (result.rows.length === 0) {
            return res.send(`
                <html>
                    <body style="font-family: Arial; text-align: center; padding: 50px;">
                        <h2 style="color: red;">Invalid or Expired Link</h2>
                        <p>The verification link is invalid or has expired.</p>
                        <p>Please register again or contact support.</p>
                    </body>
                </html>
            `);
        }
        
        await pool.query(
            'UPDATE users SET is_verified = true, verification_token = NULL WHERE user_id = $1',
            [result.rows[0].user_id]
        );
        
        res.send(`
            <html>
                <body style="font-family: Arial; text-align: center; padding: 50px;">
                    <h2 style="color: green;">✅ Email Verified Successfully!</h2>
                    <p>Your email has been verified. You can now login to AgriMarket.</p>
                    <a href="http://localhost:5000" style="background-color: #9B59B6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Go to Login</a>
                </body>
            </html>
        `);
        
    } catch (err) {
        console.error('Verification error:', err);
        res.send('<h2>Error verifying email. Please try again.</h2>');
    }
});

// ============================================
// LOGIN ENDPOINT (checks email verification)
// ============================================

app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = result.rows[0];
        
        if (!user.is_verified) {
            return res.status(401).json({ 
                error: 'Please verify your email before logging in. Check your inbox.' 
            });
        }
        
        const validPassword = await bcrypt.compare(password, user.password_hash);
        
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { id: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'your-secret-key',
            { expiresIn: '24h' }
        );
        
        const { password_hash, verification_token, token_expiry, ...userWithoutPassword } = user;
        
        res.json({ success: true, user: userWithoutPassword, token });
        
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============================================
// GET CURRENT USER
// ============================================

app.get('/api/me', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT user_id, name, phone, email, role, location, is_verified, created_at FROM users WHERE user_id = $1',
            [req.user.id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        res.json(result.rows[0]);
        
    } catch (err) {
        console.error('Error fetching user:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============================================
// USERS ENDPOINTS
// ============================================

app.get('/api/users', authenticateToken, isAdmin, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT user_id, name, phone, email, role, location, is_verified, created_at FROM users ORDER BY user_id'
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/api/users/:id', authenticateToken, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            'SELECT user_id, name, phone, email, role, location, is_verified, created_at FROM users WHERE user_id = $1',
            [id]
        );
        
        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.status(404).json({ error: "User not found" });
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/api/pending-farmers', authenticateToken, isAdmin, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT user_id as id, name, phone, location, created_at as registered 
            FROM users 
            WHERE role = 'farmer' AND is_verified = false
            ORDER BY user_id
        `);
        
        const farmers = result.rows.map(f => ({
            ...f,
            registered: f.registered ? f.registered.toISOString().split('T')[0] : '2026-03-14',
            status: 'pending'
        }));
        
        res.json(farmers);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.post('/api/approve-farmer/:id', authenticateToken, isAdmin, async (req, res) => {
    try {
        const farmerId = parseInt(req.params.id);
        
        const result = await pool.query(
            'UPDATE users SET is_verified = true WHERE user_id = $1 AND role = $2 RETURNING name',
            [farmerId, 'farmer']
        );
        
        if (result.rows.length > 0) {
            res.json({ 
                success: true, 
                message: `Farmer ${result.rows[0].name} approved successfully`,
                farmerId: farmerId
            });
        } else {
            res.status(404).json({ 
                success: false, 
                error: "Farmer not found" 
            });
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

// ============================================
// PRODUCTS ENDPOINTS
// ============================================

app.get('/api/products', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT p.*, u.name as farmer, u.location as farmer_location
            FROM products p 
            JOIN users u ON p.farmer_id = u.user_id 
            ORDER BY p.product_id DESC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.post('/api/products', authenticateToken, upload.single('image'), async (req, res) => {
    try {
        const { name, category, price, quantity, unit, description, farmerId } = req.body;
        
        let imageUrl = null;
        if (req.file) {
            imageUrl = `/uploads/${req.file.filename}`;
        }
        
        const result = await pool.query(
            `INSERT INTO products (farmer_id, name, category, price, quantity, unit, description, image_url, status) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
             RETURNING *`,
            [farmerId, name, category, price, quantity, unit, description || '', imageUrl, 'available']
        );
        
        res.status(201).json({ 
            success: true, 
            message: 'Product added successfully',
            product: result.rows[0]
        });
        
    } catch (err) {
        console.error('Error adding product:', err);
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/products/:id', authenticateToken, async (req, res) => {
    try {
        const productId = req.params.id;
        await pool.query('DELETE FROM products WHERE product_id = $1', [productId]);
        res.json({ success: true, message: 'Product deleted' });
    } catch (err) {
        console.error('Error deleting product:', err);
        res.status(500).json({ error: "Database error" });
    }
});

// ============================================
// ORDERS ENDPOINTS
// ============================================

app.post('/api/orders', authenticateToken, async (req, res) => {
    try {
        const { buyerId, productId, farmerId, quantity, unit, totalPrice, deliveryAddress } = req.body;
        
        const result = await pool.query(
            `INSERT INTO orders (buyer_id, product_id, farmer_id, quantity, unit, total_price, delivery_address, status) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending') 
             RETURNING *`,
            [buyerId, productId, farmerId, quantity, unit, totalPrice, deliveryAddress]
        );
        
        res.status(201).json({ 
            success: true, 
            message: 'Order placed successfully', 
            order: result.rows[0] 
        });
        
    } catch (err) {
        console.error('Error creating order:', err);
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/orders/my-orders', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT o.*, p.name as product_name, u.name as farmer_name 
             FROM orders o
             JOIN products p ON o.product_id = p.product_id
             JOIN users u ON o.farmer_id = u.user_id
             WHERE o.buyer_id = $1
             ORDER BY o.created_at DESC`,
            [req.user.id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/api/orders/farmer-orders', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT o.*, p.name as product_name, u.name as buyer_name 
             FROM orders o
             JOIN products p ON o.product_id = p.product_id
             JOIN users u ON o.buyer_id = u.user_id
             WHERE o.farmer_id = $1
             ORDER BY o.created_at DESC`,
            [req.user.id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

// ============================================
// STATS ENDPOINT
// ============================================

app.get('/api/stats', async (req, res) => {
    try {
        const usersResult = await pool.query('SELECT COUNT(*) FROM users');
        const totalUsers = parseInt(usersResult.rows[0].count);
        
        const productsResult = await pool.query("SELECT COUNT(*) FROM products WHERE status = 'available'");
        const activeProducts = parseInt(productsResult.rows[0].count);
        
        const pendingResult = await pool.query("SELECT COUNT(*) FROM users WHERE role = 'farmer' AND is_verified = false");
        const pendingApprovals = parseInt(pendingResult.rows[0].count);
        
        const stats = {
            totalUsers: totalUsers,
            activeProducts: activeProducts,
            pendingApprovals: pendingApprovals,
            totalTransactions: "SLE 2.4M",
            currency: "SLE",
            trends: {
                users: "+12%",
                products: "+8%",
                transactions: "+15%",
                approvals: "-5"
            }
        };
        
        res.json(stats);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/api/recent-products', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT p.product_id as id, p.name, u.name as farmer, p.category, 
                   p.price, p.unit, p.quantity, p.status, p.image_url
            FROM products p
            JOIN users u ON p.farmer_id = u.user_id
            WHERE p.status = 'available'
            ORDER BY p.listed_date DESC
            LIMIT 5
        `);
        
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
    console.log("\n=================================");
    console.log("🚀 AGRIMARKET SERVER RUNNING!");
    console.log("=================================");
    console.log(`📍 Server: http://localhost:${PORT}`);
    console.log(`📝 Test:   http://localhost:${PORT}/api/test`);
    console.log(`🔐 Login:  http://localhost:${PORT}/api/login`);
    console.log(`📝 Register: http://localhost:${PORT}/api/register`);
    console.log(`✅ Verify: http://localhost:${PORT}/api/verify-email?token=TOKEN`);
    console.log("=================================\n");
});
# 🌾 AgriMarket - Agricultural Market Linkage Platform

![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue)
![Node.js](https://img.shields.io/badge/Node.js-24.14.0-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.x-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📌 Overview

AgriMarket is a **Mobile-Based Agricultural Market Linkage Platform** designed to connect smallholder farmers in Sierra Leone directly with buyers. The platform eliminates middlemen, provides real-time market prices, and digitizes transaction records to improve income and reduce post-harvest losses.

**Project Type:** MCA Final Year Project  
**University:** Indira Gandhi National Open University (IGNOU)  
**Program:** Master of Computer Applications (MCA_NEW)  
**Course Code:** MCSP-232

---

## 🎯 Problem Statement

Smallholder farmers in Sierra Leone face significant challenges in accessing fair markets, obtaining real-time price information, and securing timely buyers for their produce.

**AgriMarket solves these problems** by providing a digital platform that connects farmers directly to buyers.

---

## ✨ Features

| Module | Features |
|--------|----------|
| **Authentication** | User registration, Login, JWT tokens, Role-based access |
| **Admin Dashboard** | Stats cards, User management, Farmer approvals |
| **Farmer Dashboard** | Add products, View products, Revenue tracking |
| **Buyer Marketplace** | Browse products, Search, Filter by category, Place orders |
| **Order System** | Order placement, Delivery address, Order confirmation |

---

## 🛠️ Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend (Mobile)** | Flutter |
| **Frontend (Web)** | HTML5, CSS3, JavaScript |
| **Backend** | Node.js, Express |
| **Database** | PostgreSQL |
| **Authentication** | JWT, bcrypt |
| **File Storage** | Cloudinary |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.5+)
- Node.js (24.14.0+)
- PostgreSQL (16.x+)

### Installation

```bash
# Clone the repository
git clone https://github.com/markyus/agrimarket-platform-mca.git

# Setup Backend
cd backend
npm install
node server.js

# Setup Flutter App
cd ../mobile_app
flutter pub get
flutter run -d chrome

API Documentation
Endpoint	Method	Description
/api/register	POST	User registration
/api/login	POST	User login
/api/users	GET	Get all users
/api/products	GET	Get all products
/api/products	POST	Add new product
/api/orders	POST	Place order

👨‍💻 Author
Yusif Fuad Kamara
MCA Student, IGNOU
📧 yusiffkamara@gmail.com
📍 Sierra Leone

🙏 Acknowledgements
Project Guide: Ibrahim Shour, Head of IT, Access Bank Sierra Leone

IGNOU School of Computer and Information Sciences

📄 License
This project is licensed under the MIT License.

Built with ❤️ for Sierra Leonean Farmers





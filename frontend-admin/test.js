// ============================================
// JAVASCRIPT BASICS - Complete Learning Example
// ============================================

console.log("=================================");
console.log("JAVASCRIPT LEARNING EXAMPLES");
console.log("=================================\n");

// 1. VARIABLES
console.log("1. VARIABLES:");
let userName = "Admin";
const appName = "AgriMarket";
console.log("Hello, " + userName);
console.log("Welcome to " + appName + "\n");

// 2. DATA TYPES
console.log("2. DATA TYPES:");
let name = "Amara Sesay";              // String
let age = 35;                          // Number
let isVerified = true;                  // Boolean
let products = ["Rice", "Cassava", "Groundnuts"];  // Array
let farmer = {                          // Object
    name: "Amara",
    location: "Makeni",
    phone: "232-76-123456"
};

console.log("Farmer name: " + farmer.name);
console.log("First product: " + products[0]);
console.log("Age: " + age);
console.log("Verified: " + isVerified + "\n");

// 3. FUNCTIONS
console.log("3. FUNCTIONS:");
function greetUser(name) {
    return "Welcome, " + name + "!";
}

function calculateTotal(price, quantity) {
    return price * quantity;
}

let message = greetUser("Yusif");
console.log(message);

let total = calculateTotal(50, 10);
console.log("Total: SLE " + total + "\n");

// 4. CONDITIONS
console.log("4. CONDITIONS:");
let userRole = "admin";

if (userRole === "admin") {
    console.log("You have full access");
} else if (userRole === "farmer") {
    console.log("You can list products");
} else {
    console.log("You can only view");
}
console.log("");

// 5. LOOPS
console.log("5. LOOPS:");
console.log("Listing all products:");
for (let i = 0; i < products.length; i++) {
    console.log("  - " + products[i]);
}
console.log("");

// 6. ARROW FUNCTIONS
console.log("6. ARROW FUNCTIONS:");
const multiply = (a, b) => a * b;
console.log("5 × 3 = " + multiply(5, 3) + "\n");

// 7. ARRAY METHODS
console.log("7. ARRAY METHODS:");
let prices = [50, 30, 40, 25];

// Filter
let highPrices = prices.filter(price => price > 30);
console.log("Prices above 30:", highPrices);

// Map
let priceStrings = prices.map(price => "SLE " + price);
console.log("Formatted prices:", priceStrings);

// Reduce
let totalSum = prices.reduce((sum, price) => sum + price, 0);
console.log("Total of all prices: SLE " + totalSum + "\n");

console.log("=================================");
console.log("✅ JavaScript learning complete!");
console.log("=================================");
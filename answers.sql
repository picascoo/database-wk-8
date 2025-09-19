-- Library Management System Database
-- Created by [Your Name]
-- Date: [Current Date]

-- Create the database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Table 1: Members - Stores library members information
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    date_of_birth DATE NOT NULL,
    membership_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_status ENUM('Active', 'Suspended', 'Expired') DEFAULT 'Active',
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_age CHECK (DATEDIFF(CURRENT_DATE, date_of_birth) / 365.25 >= 16)
);

-- Table 2: Authors - Stores book authors information
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    nationality VARCHAR(50),
    birth_date DATE,
    death_date DATE,
    biography TEXT,
    CONSTRAINT chk_dates CHECK (death_date IS NULL OR birth_date < death_date)
);

-- Table 3: Publishers - Stores publisher information
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    phone VARCHAR(15),
    email VARCHAR(100),
    website VARCHAR(200),
    CONSTRAINT chk_publisher_email CHECK (email LIKE '%@%.%')
);

-- Table 4: Books - Stores book information
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    publication_year YEAR,
    edition VARCHAR(20),
    genre VARCHAR(50) NOT NULL,
    language VARCHAR(30) DEFAULT 'English',
    page_count INT,
    publisher_id INT,
    shelf_location VARCHAR(20) NOT NULL,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) 
        REFERENCES Publishers(publisher_id) ON DELETE SET NULL,
    CONSTRAINT chk_isbn_length CHECK (LENGTH(isbn) = 10 OR LENGTH(isbn) = 13),
    CONSTRAINT chk_publication_year CHECK (publication_year BETWEEN 1450 AND YEAR(CURRENT_DATE)),
    CONSTRAINT chk_copies CHECK (available_copies <= total_copies AND total_copies >= 0 AND available_copies >= 0)
);

-- Table 5: Book_Authors - Many-to-Many relationship between Books and Authors
CREATE TABLE Book_Authors (
    book_id INT,
    author_id INT,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book_author_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_author_author FOREIGN KEY (author_id) 
        REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- Table 6: Loans - Tracks book loans to members
CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE,
    loan_status ENUM('Active', 'Returned', 'Overdue') DEFAULT 'Active',
    late_fee DECIMAL(8,2) DEFAULT 0.00,
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_due_date CHECK (due_date > loan_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= loan_date),
    CONSTRAINT chk_late_fee CHECK (late_fee >= 0)
);

-- Table 7: Reservations - Tracks book reservations
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Fulfilled', 'Cancelled') DEFAULT 'Pending',
    priority INT DEFAULT 1,
    notification_sent BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_priority CHECK (priority BETWEEN 1 AND 5),
    CONSTRAINT unique_active_reservation UNIQUE (book_id, member_id, status)
);

-- Table 8: Fines - Tracks member fines
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    loan_id INT,
    amount DECIMAL(8,2) NOT NULL,
    issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    paid_date DATE,
    status ENUM('Unpaid', 'Paid', 'Waived') DEFAULT 'Unpaid',
    reason TEXT NOT NULL,
    CONSTRAINT fk_fine_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) 
        REFERENCES Loans(loan_id) ON DELETE SET NULL,
    CONSTRAINT chk_fine_amount CHECK (amount > 0),
    CONSTRAINT chk_paid_date CHECK (paid_date IS NULL OR paid_date >= issue_date)
);

-- Table 9: Staff - Library staff members
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2),
    department VARCHAR(50),
    CONSTRAINT chk_staff_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_salary CHECK (salary >= 0)
);

-- Table 10: Library_Branches - Multiple library branches
CREATE TABLE Library_Branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    opening_hours TEXT,
    manager_id INT,
    CONSTRAINT fk_branch_manager FOREIGN KEY (manager_id) 
        REFERENCES Staff(staff_id) ON DELETE SET NULL,
    CONSTRAINT chk_branch_email CHECK (email LIKE '%@%.%')
);

-- Table 11: Book_Copies - Tracks individual book copies across branches
CREATE TABLE Book_Copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    branch_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    acquisition_date DATE DEFAULT (CURRENT_DATE),
    condition ENUM('New', 'Good', 'Fair', 'Poor', 'Withdrawn') DEFAULT 'Good',
    current_status ENUM('Available', 'On Loan', 'Reserved', 'Under Repair', 'Lost') DEFAULT 'Available',
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_copy_branch FOREIGN KEY (branch_id) 
        REFERENCES Library_Branches(branch_id) ON DELETE CASCADE
);

-- Table 12: Transactions - Audit trail for all library transactions
CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    staff_id INT,
    transaction_type ENUM('Loan', 'Return', 'Reservation', 'Fine Payment', 'Membership') NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(8,2) DEFAULT 0.00,
    description TEXT,
    CONSTRAINT fk_transaction_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE SET NULL,
    CONSTRAINT fk_transaction_staff FOREIGN KEY (staff_id) 
        REFERENCES Staff(staff_id) ON DELETE SET NULL
);

-- Indexes for better performance
CREATE INDEX idx_books_title ON Books(title);
CREATE INDEX idx_books_genre ON Books(genre);
CREATE INDEX idx_members_email ON Members(email);
CREATE INDEX idx_loans_due_date ON Loans(due_date);
CREATE INDEX idx_loans_status ON Loans(loan_status);
CREATE INDEX idx_reservations_status ON Reservations(status);
CREATE INDEX idx_fines_status ON Fines(status);
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);

-- Insert sample data
INSERT INTO Publishers (name, address, phone, email, website) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', '212-782-9000', 'info@penguinrandomhouse.com', 'https://www.penguinrandomhouse.com'),
('HarperCollins', '195 Broadway, New York, NY 10007', '212-207-7000', 'contact@harpercollins.com', 'https://www.harpercollins.com'),
('Macmillan', '120 Broadway, New York, NY 10271', '646-307-5151', 'info@macmillan.com', 'https://www.macmillan.com');

INSERT INTO Authors (first_name, last_name, nationality, birth_date, death_date) VALUES
('George', 'Orwell', 'British', '1903-06-25', '1950-01-21'),
('J.K.', 'Rowling', 'British', '1965-07-31', NULL),
('Stephen', 'King', 'American', '1947-09-21', NULL),
('Jane', 'Austen', 'British', '1775-12-16', '1817-07-18');

INSERT INTO Books (isbn, title, publication_year, edition, genre, language, page_count, publisher_id, shelf_location, total_copies, available_copies) VALUES
('9780451524935', '1984', 1949, '1st', 'Dystopian Fiction', 'English', 328, 1, 'Fiction A-101', 5, 5),
('9780439064866', 'Harry Potter and the Chamber of Secrets', 1998, '1st', 'Fantasy', 'English', 341, 2, 'Fantasy B-205', 3, 3),
('9781501142970', 'It', 1986, '1st', 'Horror', 'English', 1138, 3, 'Horror C-304', 2, 2),
('9780141439518', 'Pride and Prejudice', 1813, 'Revised', 'Romance', 'English', 432, 1, 'Classics D-102', 4, 4);

INSERT INTO Book_Authors (book_id, author_id) VALUES
(1, 1), -- 1984 by George Orwell
(2, 2), -- Harry Potter by J.K. Rowling
(3, 3), -- It by Stephen King
(4, 4); -- Pride and Prejudice by Jane Austen

-- Display database structure information
SELECT 'Library Management System Database Created Successfully!' AS Status;
SELECT COUNT(*) AS 'Tables Created' FROM information_schema.tables 
WHERE table_schema = 'LibraryManagementSystem';

-- Show table relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'LibraryManagementSystem' 
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;
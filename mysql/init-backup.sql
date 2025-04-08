CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON db_nuconnect.* TO 'admin'@'%';
FLUSH PRIVILEGES;
DROP DATABASE IF EXISTS db_nuconnect;
CREATE DATABASE db_nuconnect;
USE db_nuconnect;

CREATE TABLE tbl_role(
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tbl_department(
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    description VARCHAR(255)
);

CREATE TABLE tbl_user(
    user_id VARCHAR(200) UNIQUE NOT NULL PRIMARY KEY,
    f_name VARCHAR(50) NOT NULL,
    l_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    role_id INT NOT NULL DEFAULT 1,
    profile_picture VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES tbl_role(role_id)
);

CREATE TABLE tbl_permission(
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tbl_role_permission(
    role_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

-- Organization Table
CREATE TABLE tbl_organization(
    organization_id INT AUTO_INCREMENT PRIMARY KEY,
    adviser_id VARCHAR(200) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo VARCHAR(255),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    approve_status INT, 
    membership_fee_type ENUM('Per Term', 'Whole Academic Year') NOT NULL,
    membership_fee_amount DECIMAL(10,2) NOT NULL,
    is_recruiting BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adviser_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

CREATE TABLE tbl_organization_requirements(
    requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_organization_role(
    organization_role_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    role_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE
);

CREATE TABLE tbl_organization_role_permission(
    org_role_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_role_id INT NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_role_id) REFERENCES tbl_organization_role(organization_role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_approval_process(
    approval_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    approver_id VARCHAR(200) NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    comment TEXT,
    step INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

-- Committees Table
CREATE TABLE tbl_committee(
    committee_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_committee_role(
    committee_role_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_id INT NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES tbl_committee(committee_id) ON DELETE CASCADE
);

CREATE TABLE tbl_committee_role_permission(
    committee_role_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_role_id INT NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_role_id) REFERENCES tbl_committee_role(committee_role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_executive_members(
    executive_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    `rank` VARCHAR(100) NOT NULL,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

CREATE TABLE tbl_membership_fees(
    fee_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

CREATE TABLE tbl_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    department_id INT NULL, -- tied to tbl_department if null it means all students can join
    user_id VARCHAR(200) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT NOT NULL,
    venue VARCHAR(200) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', "Archived") DEFAULT 'Pending',
    type ENUM("Paid","Free"),
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES tbl_department(department_id)
);

	CREATE TABLE tbl_event_attendance(
		attendance_id INT AUTO_INCREMENT PRIMARY KEY,
		event_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		status ENUM('Registered', 'Not Registered') NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_feedback(
		feedback_id INT AUTO_INCREMENT PRIMARY KEY,
		event_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		message TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_feedback_question(
		question_id INT AUTO_INCREMENT PRIMARY KEY,
		feedback_id INT NOT NULL,
		question_text TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (feedback_id) REFERENCES tbl_feedback(feedback_id) ON DELETE CASCADE
	);
    
    CREATE TABLE tbl_application_field (
    field_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    field_type ENUM('text', 'textarea', 'number', 'date', 'file', 'select') NOT NULL,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_application_form (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(200) NOT NULL,
    organization_id INT NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_application_response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    field_id INT NOT NULL,
    response TEXT NOT NULL, -- Store the actual response (text, file path, etc.)
    FOREIGN KEY (application_id) REFERENCES tbl_application_form(application_id) ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES tbl_application_field(field_id) ON DELETE CASCADE
);

CREATE TABLE tbl_logs(
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(200) NOT NULL,
    action TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

INSERT INTO tbl_role(role_name)
VALUES("STUDENT"), 
("ADVISER"),
("PROGRAMCHAIR"),
("SDAO"),
("DEAN");

INSERT INTO tbl_user (user_id, f_name, l_name, email, role_id) VALUES
("900f929ec408cb4d","Benz","Jav","benz@gmail.com",2), ("900f929ec408cb4","Benson","Javier","benson09.javier@outlook.com",1);

INSERT INTO tbl_organization (adviser_id, status, name, approve_status, membership_fee_type, membership_fee_amount) VALUES
("900f929ec408cb4d","PENDING", "COMPSOC", 5,"Per Term",500.0);


-- PROCEDURES
use db_nuconnect;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetAllEvents(
)
BEGIN
SELECT 
    a.event_id, 
    a.title,
    a.user_id, 
    b.name as organization_name,
    a.description, 
    a.start_time, 
    a.end_time, 
    a.date, 
    a.created_at
FROM tbl_event a
LEFT JOIN tbl_organization b ON a.organization_id = b.organization_id
LEFT JOIN tbl_department c ON a.department_id = c.department_id
WHERE a.status = "Approved" AND a.date >= CURDATE()
ORDER BY a.date ASC;
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEmail(
	IN Email VARCHAR(30)
)
BEGIN

	SELECT * FROM tbl_user where email = Email;
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetSpecificEvent(
IN eventId INT, 
   userId VARCHAR(30)
)
BEGIN
SELECT a.event_id, 
a.title,
a.description,
c.name as organization_name,
a.venue, 
a.start_time, 
a.end_time, 
a.status, 
a.type, 
a.date, 
COALESCE(b.status, "Not Registered") as student_status
FROM tbl_event a
LEFT JOIN tbl_event_attendance b ON a.event_id = b.event_id AND b.user_id = userId
LEFT JOIN tbl_organization c ON a.organization_id = c.organization_id
WHERE a.event_id = eventId;
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEventAttendees(
	IN eventId INT
)
BEGIN
	SELECT a.event_id, b.f_name, b.l_name, a.status
FROM tbl_event_attendance a 
LEFT JOIN tbl_user b ON a.user_id = b.user_id
WHERE a.status = "Registered" AND a.event_id = eventId;
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CreateEvent(IN
	user_id VARCHAR(200),
    title VARCHAR(300),
	description TEXT,
	venue VARCHAR(200),
    date date,
    start_time time,
    end_time time,
    organization_id INT,
    department_id INT,
    type VARCHAR(10),
    status VARCHAR(10)
)
BEGIN
INSERT INTO tbl_event (
user_id, 
title, 
description, 
venue, date, 
start_time, 
end_time, 
organization_id, 
department_id, 
type,
status
) 
VALUES (user_id, 
title, 
description, 
venue, 
date, 
start_time, 
end_time, 
organization_id, 
department_id, 
type,
status
);
SELECT 
    a.event_id, 
    a.title,
    a.user_id, 
    b.name as organization_name,
    a.description, 
    a.start_time, 
    a.end_time, 
    a.date, 
    a.created_at
FROM tbl_event a
LEFT JOIN tbl_organization b ON a.organization_id = b.organization_id
LEFT JOIN tbl_department c ON a.department_id = c.department_id
WHERE a.status = "Approved" AND a.date >= CURDATE() AND a.event_id = LAST_INSERT_ID();
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE RegisterEvent(IN
	event_id INT,   
    user_id VARCHAR(200)
)
BEGIN
INSERT INTO tbl_event_attendance (event_id, user_id, status) 
VALUES (event_id, user_id, "Registered");
SELECT * FROM tbl_event_attendance WHERE attendance_id = LAST_INSERT_ID();
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CheckEventRegistration(IN
	event_id INT,
    user_id VARCHAR(200)
)
BEGIN
SELECT * FROM tbl_event_attendance a WHERE a.event_id = event_id AND a.user_id = user_id;
END $$
DELIMITER ;
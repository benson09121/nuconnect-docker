-- Create user if not exists
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON db_nuconnect.* TO 'admin'@'%';
FLUSH PRIVILEGES;

	DROP DATABASE IF EXISTS db_nuconnect;
	CREATE DATABASE db_nuconnect;
	USE db_nuconnect;

	CREATE TABLE tbl_role(
		role_id INT AUTO_INCREMENT PRIMARY KEY,
		role_name VARCHAR(100) UNIQUE NOT NULL,
		role_type ENUM('School','System', 'Organization') NOT NULL,
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

	CREATE TABLE tbl_organization(
		organization_id INT AUTO_INCREMENT PRIMARY KEY,
		adviser_id VARCHAR(200) NOT NULL,
		status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
		approve_status INT, -- 1 Adviser, 2 Program Chair, 3 Dean, 4 SDAO, 5 Complete
		organization_classification ENUM('Academic','Non-Academic') NOT NULL,
		base_department_id INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (adviser_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
		FOREIGN KEY (base_department_id) REFERENCES tbl_department(department_id)
	);

	CREATE TABLE tbl_organization_requirements(
		requirement_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		file_path VARCHAR(255) NOT NULL,
		uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_approval_flow (
		flow_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		role_id INT NOT NULL,
		step_order INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
		FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_approval_status (
		approval_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		role_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
		comment TEXT NULL,
		approved_at TIMESTAMP NULL DEFAULT NULL,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
		FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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

	CREATE TABLE tbl_organization_members(
		members_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		organization_role_id INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
		FOREIGN KEY (organization_role_id) REFERENCES tbl_organization_role(organization_role_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_committee(
		committee_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		created_by VARCHAR(200) NOT NULL,
		committee_name VARCHAR(100) NOT NULL UNIQUE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
		FOREIGN KEY (created_by) REFERENCES tbl_user(user_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_committee_members(
		committee_member_id INT AUTO_INCREMENT PRIMARY KEY,
		committee_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		role_id INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (committee_id) REFERENCES tbl_committee(committee_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
		FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_organization_storage(
		file_id INT AUTO_INCREMENT PRIMARY KEY,
		organization_id INT NOT NULL,
		uploaded_by VARCHAR(200) NOT NULL,
		file_name VARCHAR(255) NOT NULL,
		file_path VARCHAR(255) NOT NULL,
		uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
		FOREIGN KEY (uploaded_by) REFERENCES tbl_user(user_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_event(
		event_id INT AUTO_INCREMENT PRIMARY KEY,
		user_id VARCHAR(200) NOT NULL,
		title VARCHAR(300) NOT NULL,
		description TEXT NOT NULL,
		start_time TIME NOT NULL,
		end_time TIME NOT NULL,
		date DATE NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
	);

	CREATE TABLE tbl_event_attendance(
		attendance_id INT AUTO_INCREMENT PRIMARY KEY,
		event_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		status ENUM('Going', 'Not Going') NOT NULL,
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
INSERT INTO tbl_role(role_name, role_type) VALUES("Student","School");
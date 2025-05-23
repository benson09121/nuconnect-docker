CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON db_nuconnect.* TO 'admin'@'%';
-- GRANT EVENT ON db_nuconnect.* TO 'admin'@'%';
FLUSH PRIVILEGES;

-- GRANT EVENT ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;

-- Sets the Timezone to GMT+08 Timezone for the Pilipinas! 
SET GLOBAL time_zone = '+8:00';
SET GLOBAL event_scheduler = ON;

 
DROP DATABASE IF EXISTS db_nuconnect;
CREATE DATABASE db_nuconnect;
USE db_nuconnect;

CREATE TABLE tbl_role(
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(100) UNIQUE NOT NULL,
    is_approver BOOLEAN DEFAULT FALSE,
    hierarchy_order INT UNIQUE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE tbl_approval_role (
    approval_role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_Id INT NOT NULL,
    hierarchy_order INT UNIQUE NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE
);

CREATE TABLE tbl_program(
    program_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE tbl_user(
    user_id VARCHAR(200) UNIQUE NOT NULL PRIMARY KEY,
    f_name VARCHAR(50) NULL,
    l_name VARCHAR(50) NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    program_id INT NULL,
    role_id INT NOT NULL,
    profile_picture VARCHAR(255),
    status ENUM('Active', 'Pending', 'Archive') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    archived_at TIMESTAMP NULL,
    FOREIGN KEY (role_id) REFERENCES tbl_role(role_id),
    FOREIGN KEY (program_id) REFERENCES tbl_program(program_id)
);

CREATE TABLE tbl_permission(
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(200) UNIQUE NOT NULL,
    scope ENUM('Global', 'Executive', 'Committee') DEFAULT 'Global',
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
    name VARCHAR(100) NOT NULL,
    description TEXT,
    base_program_id INT NULL, -- NULL meaning open to all
    logo VARCHAR(255),
    status ENUM('Pending', 'Approved', 'Rejected', 'Renewal') DEFAULT 'Pending',
    membership_fee_type ENUM('Per Term', 'Whole Academic Year') NOT NULL,
    category ENUM('Co-Curricular Organization', 'Extra Curricular Organization') DEFAULT 'Co-Curricular Organization',
    membership_fee_amount DECIMAL(10,2) NOT NULL,
    is_recruiting BOOLEAN DEFAULT FALSE,
    is_open_to_all_courses BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adviser_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_renewal_cycle (
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    start_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    president_id VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (organization_id, cycle_number),
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (president_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_organization_course(
	organization_id INT NOT NULL,
    program_id INT NOT NULL,
    PRIMARY KEY (organization_id,program_id),
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES tbl_program(program_id) ON DELETE CASCADE	
);

CREATE TABLE tbl_executive_rank (
    rank_id INT AUTO_INCREMENT PRIMARY KEY,
    rank_level INT UNIQUE NOT NULL,
    default_title VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tbl_executive_role (
    executive_role_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    role_title VARCHAR(100) NOT NULL,  -- e.g., 'President', 'Vice-President'
    rank_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE,
    FOREIGN KEY (rank_id) REFERENCES tbl_executive_rank(rank_id)
);

CREATE TABLE tbl_rank_permission (
    rank_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (rank_id, permission_id),
    FOREIGN KEY (rank_id) REFERENCES tbl_executive_rank(rank_id),
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id)
);

CREATE TABLE tbl_organization_members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    member_type ENUM('Member', 'Executive', 'Committee') DEFAULT 'Member',
    executive_role_id INT DEFAULT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE,
    FOREIGN KEY (executive_role_id) REFERENCES tbl_executive_role (executive_role_id) ON DELETE SET NULL
);

CREATE TABLE tbl_executive_member_permission (
    executive_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    organization_id INT NULL,  -- references tbl_organization_members
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES tbl_organization_members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_membership_fees(
    fee_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_committee (
    committee_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE
);

CREATE TABLE tbl_committee_members(
    committee_member_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    role ENUM('Committee Head', 'Committee Officer') DEFAULT 'Committee Officer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES tbl_committee(committee_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_committee_role (
    committee_role_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_id INT NOT NULL,
    role_name VARCHAR(100) NOT NULL,  -- e.g., 'Committee Head', 'Committee Member'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES tbl_committee(committee_id) ON DELETE CASCADE
);

CREATE TABLE tbl_committee_role_permission (
    committee_role_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_role_id INT NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_role_id) REFERENCES tbl_committee_role(committee_role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT NOT NULL,
    venue_type ENUM('Face to face', 'Online') DEFAULT 'face to face',
    venue VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', "Archived") DEFAULT 'Pending',
    type ENUM("Paid","Free"),
    is_open_to ENUM("Members only", "Open to all", "NU Students only") DEFAULT "Members only",
    fee INT NULL,
    capacity INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    certificate VARCHAR(1000) DEFAULT NULL,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_event_requirements(
    requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    requirement_type ENUM('PRE-EVENT', 'POST-EVENT') NOT NULL,
    requirement_name VARCHAR(255) NOT NULL,
    requirement_file_path VARCHAR(255) NOT NULL,
    created_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES tbl_user(user_id) ON UPDATE CASCADE

);

CREATE TABLE tbl_event_requirement_submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    requirement_id INT NOT NULL,
    cycle_number INT NOT NULL,
    organization_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    submitted_by VARCHAR(200) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id),
    FOREIGN KEY (requirement_id) REFERENCES tbl_event_requirements(requirement_id),
    FOREIGN KEY (submitted_by) REFERENCES tbl_user(user_id),
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE
);

CREATE TABLE tbl_event_course(
	event_id INT NOT NULL,
	program_id INT NOT NULL,
    PRIMARY KEY (event_id, program_id),
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id),
    FOREIGN KEY (program_id) REFERENCES tbl_program(program_id)
);

CREATE TABLE tbl_event_attendance(
		attendance_id INT AUTO_INCREMENT PRIMARY KEY,
		event_id INT NOT NULL,
		user_id VARCHAR(200) NOT NULL,
		status ENUM('Registered', 'Not Registered','Attended') NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_certificate_template (
    template_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL UNIQUE, 
    template_path VARCHAR(255) NOT NULL,
    uploaded_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_event_certificate (
    certificate_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    template_id INT NOT NULL,
    certificate_path VARCHAR(255) NOT NULL,
    verification_code VARCHAR(36) UNIQUE NOT NULL,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE,
    FOREIGN KEY (template_id) REFERENCES tbl_certificate_template(template_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_cert (event_id, user_id) -- One cert per user per event
);

CREATE TABLE tbl_project_heads (
    project_head_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    event_id INT NOT NULL,
    role_type ENUM('Executive', 'Committee') NOT NULL,
    project_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE
);

CREATE TABLE tbl_evaluation_question_group (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_title VARCHAR(255) NOT NULL,
    group_description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE tbl_evaluation_question (
    question_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('textbox', 'likert_4') NOT NULL,
    is_required BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (group_id) REFERENCES tbl_evaluation_question_group(group_id)
);

CREATE TABLE tbl_event_evaluation_config (
    event_id INT NOT NULL,
    group_id INT NOT NULL,
    PRIMARY KEY (event_id, group_id),
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES tbl_evaluation_question_group(group_id)
);

CREATE TABLE tbl_evaluation (
    evaluation_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INT DEFAULT NULL,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id),
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_evaluation_response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    evaluation_id INT NOT NULL,
    question_id INT NOT NULL,
    response_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (evaluation_id) REFERENCES tbl_evaluation(evaluation_id)
);

CREATE TABLE tbl_application_period (
    period_id INT AUTO_INCREMENT PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_approval_process(
    approval_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    period_id INT NULL,
    approver_id VARCHAR(200) NOT NULL,
    approval_role_id INT NOT NULL,
    application_type ENUM('new', 'renewal') NOT NULL DEFAULT 'new',
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    comment TEXT,
    step INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES tbl_application_period(period_id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE,
    FOREIGN KEY (approval_role_id) REFERENCES tbl_role(role_id) ON DELETE CASCADE
);

CREATE TABLE tbl_application (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NULL, -- Existing org for renewals
    cycle_number INT NULL, -- Existing org for renewals
    application_type ENUM('new', 'renewal') NOT NULL,
    period_id INT NOT NULL,
    applicant_user_id VARCHAR(200) NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE SET NULL ,
    FOREIGN KEY (period_id) REFERENCES tbl_application_period(period_id),
    FOREIGN KEY (applicant_user_id) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_application_approval (
    application_id INT NOT NULL,
    approval_id INT NOT NULL,
    PRIMARY KEY (application_id, approval_id),
    FOREIGN KEY (application_id) REFERENCES tbl_application(application_id),
    FOREIGN KEY (approval_id) REFERENCES tbl_approval_process(approval_id)
);

CREATE TABLE tbl_application_requirement (
    requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    requirement_name VARCHAR(255) NOT NULL,
    is_applicable_to ENUM('new', 'renew', 'both') DEFAULT 'new',
    file_path VARCHAR(255) NULL,
    created_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_organization_requirement_submission (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT,
    requirement_id INT NOT NULL,
    cycle_number INT NOT NULL,
    organization_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    submitted_by VARCHAR(200) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES tbl_application(application_id),
    FOREIGN KEY (requirement_id) REFERENCES tbl_application_requirement(requirement_id),
    FOREIGN KEY (submitted_by) REFERENCES tbl_user(user_id),
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE
);

-- Notifications Table: Stores the core notification details
CREATE TABLE tbl_notification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id VARCHAR(200) DEFAULT NULL,  
    entity_type ENUM('event', 'approval', 'organization', 'transaction', 'general') NOT NULL,
    entity_id INT DEFAULT NULL,      
    title VARCHAR(255) NOT NULL,          
    message TEXT NOT NULL,              
    url VARCHAR(255) DEFAULT NULL,     
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tbl_notification_recipient (
    notification_recipient_id INT AUTO_INCREMENT PRIMARY KEY,
    notification_id INT NOT NULL,        
    recipient_type ENUM('user', 'organization', 'program') NOT NULL,
    recipient_id VARCHAR(200) NOT NULL,    
    is_read BOOLEAN DEFAULT FALSE,         
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notification_id) REFERENCES tbl_notification(notification_id) ON DELETE CASCADE
);

-- CREATE TABLE tbl_logs(
--     log_id INT AUTO_INCREMENT PRIMARY KEY,
--     user_id VARCHAR(200) NOT NULL,
--     action TEXT NOT NULL,
--     timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
-- );

    -- Improved table for logs
CREATE TABLE tbl_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(200) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT NOT NULL,
    redirect_url VARCHAR(500) DEFAULT NULL,
    file_path TEXT DEFAULT NULL, -- can store JSON array as string
    meta_data JSON DEFAULT NULL, -- flexible key-value storage
    type VARCHAR(100) DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);


CREATE TABLE tbl_transaction(
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type ENUM('Membership Fee', 'Event Fee', 'Event Expenses') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    proof_image VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
);

CREATE TABLE tbl_transaction_membership(
    transaction_id INT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES tbl_transaction(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE
);

CREATE TABLE tbl_transaction_event(
    transaction_id INT PRIMARY KEY,
    event_id INT NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES tbl_transaction(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE
);


-- PROCEDURES
use db_nuconnect;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetAllEvents(IN p_user_id VARCHAR(200))
BEGIN
    DECLARE v_program_id INT;
    
    -- Get user's program
    SELECT program_id INTO v_program_id 
    FROM tbl_user 
    WHERE user_id = p_user_id;

    -- Get all organizations the user belongs to
    WITH UserOrganizations AS (
        SELECT organization_id 
        FROM tbl_organization_members 
        WHERE user_id = p_user_id
        
        UNION
        
        SELECT c.organization_id 
        FROM tbl_committee_members cm
        JOIN tbl_committee c ON cm.committee_id = c.committee_id
        WHERE cm.user_id = p_user_id
    )
    
    SELECT
        e.event_id,
        e.title,
        e.user_id AS organizer_id,
        o.name AS organization_name,
        e.description,
        e.venue,
        e.start_time,
        e.end_time,
        e.start_date,
        e.end_date,
        e.created_at,
        e.status,
        e.type,
        CASE 
            WHEN e.is_open_to_all THEN 'Open to All'
            ELSE 'Restricted'
        END AS access_type,
        COALESCE(e.fee, 0) AS event_fee,
        e.capacity,
        CASE 
            WHEN TIMESTAMP(e.end_date, e.end_time) < CURRENT_TIMESTAMP THEN 'Ended'
            ELSE 'Upcoming'
        END AS event_status,
        e.certificate AS certificate_available
    FROM tbl_event e
    INNER JOIN tbl_organization o ON e.organization_id = o.organization_id
    LEFT JOIN UserOrganizations uo ON e.organization_id = uo.organization_id
    WHERE e.status = 'Approved'
      AND (
          e.is_open_to_all = TRUE
          OR EXISTS (
              SELECT 1 
              FROM tbl_event_course ec 
              WHERE ec.event_id = e.event_id 
                AND ec.program_id = v_program_id
          )
          OR uo.organization_id IS NOT NULL
      )
    ORDER BY 
        CASE 
            WHEN TIMESTAMP(e.end_date, e.end_time) < CURRENT_TIMESTAMP THEN 1 
            ELSE 0 
        END,
        e.start_date ASC,
        e.start_time ASC;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEmail(
    IN p_email VARCHAR(100)
)
BEGIN
    SELECT * FROM tbl_user WHERE email = p_email;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetSpecificEvent(
IN eventId INT, 
   userId VARCHAR(200)
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
a.start_date,
a.end_date,
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
    p_user_id VARCHAR(200),
    p_title VARCHAR(300),
    p_description TEXT,
    p_venue VARCHAR(200),
    p_start_date DATE,
    p_end_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_organization_id INT,
    p_status ENUM('Pending', 'Approved', 'Rejected', 'Archived'),
    p_type ENUM('Paid', 'Free'),
    p_is_open_to_all BOOLEAN
)
BEGIN
    DECLARE v_base_program_id INT;
    DECLARE v_event_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT base_program_id INTO v_base_program_id 
    FROM tbl_organization 
    WHERE organization_id = p_organization_id;


    IF p_is_open_to_all = FALSE AND v_base_program_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot create restricted event for open organization';
    END IF;
 
    INSERT INTO tbl_event (
        organization_id,
        user_id,
        title,
        description,
        venue,
        start_date,
        end_date,
        start_time,
        end_time,
        status,
        type,
        is_open_to_all
    ) VALUES (
        p_organization_id,
        p_user_id,
        p_title,
        p_description,
        p_venue,
        p_start_date,
        p_end_date,
        p_start_time,
        p_end_time,
        p_status,
        p_type,
        p_is_open_to_all
    );
    
    SET v_event_id = LAST_INSERT_ID();

    IF p_is_open_to_all = FALSE THEN
        INSERT INTO tbl_event_course (event_id, program_id)
        SELECT v_event_id, program_id
        FROM (
            SELECT base_program_id AS program_id
            FROM tbl_organization
            WHERE organization_id = p_organization_id
            UNION
            SELECT program_id
            FROM tbl_organization_course
            WHERE organization_id = p_organization_id
        ) AS org_courses;
    END IF;

    COMMIT;
    SELECT * FROM tbl_event WHERE event_id = v_event_id;
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

DROP PROCEDURE IF EXISTS GetAffectedUsers;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetUserEventRegistrations(IN p_user_id VARCHAR(200))
BEGIN
    SELECT 
        ea.attendance_id,
        e.event_id,
        e.title,
        e.start_date,
        e.end_date,
        e.start_time,
        e.venue,
        o.name AS organization_name,
        ea.status,
        ea.created_at AS registration_date
    FROM tbl_event_attendance ea
    INNER JOIN tbl_event e ON ea.event_id = e.event_id
    INNER JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE (ea.user_id = p_user_id) AND (ea.status = "Registered" OR ea.status = "Attended")
    ORDER BY e.start_date DESC, e.start_time DESC;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizations(IN p_user_id VARCHAR(200))
BEGIN
    SELECT 
        o.organization_id,
        o.name AS organization_name,
        o.logo,
        o.description AS organization_description,
        o.category AS organization_type,
        (
            SELECT COUNT(*) 
            FROM tbl_organization_members 
            WHERE organization_id = o.organization_id
        ) + (
            SELECT COUNT(DISTINCT cm.user_id)
            FROM tbl_committee c
            JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
            WHERE c.organization_id = o.organization_id
            AND cm.user_id NOT IN (
                SELECT user_id 
                FROM tbl_organization_members 
                WHERE organization_id = o.organization_id
            )
        ) AS total_members,
        (
            SELECT GROUP_CONCAT(u.profile_picture ORDER BY RAND() SEPARATOR ',')
            FROM (
                SELECT u.profile_picture
                FROM tbl_organization_members om
                JOIN tbl_user u ON om.user_id = u.user_id
                WHERE om.organization_id = o.organization_id
                UNION
                SELECT u.profile_picture
                FROM tbl_committee_members cm
                JOIN tbl_user u ON cm.user_id = u.user_id
                JOIN tbl_committee c ON cm.committee_id = c.committee_id
                WHERE c.organization_id = o.organization_id
                LIMIT 4
            ) AS u
        ) AS member_profile_pictures,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM tbl_organization_members om 
                WHERE om.organization_id = o.organization_id 
                AND om.user_id = p_user_id
            ) THEN 1
            WHEN EXISTS (
                SELECT 1 
                FROM tbl_committee c
                JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
                WHERE c.organization_id = o.organization_id
                AND cm.user_id = p_user_id
            ) THEN 1
            ELSE 0
        END AS has_joined,
        (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'event_start_date', e.start_date,
                'event_end_date', e.end_date,
                'event_title', e.title,
                'start_time', e.start_time,
                'end_time', e.end_time,
                'venue', e.venue,
                'attendee_images', (
                    SELECT GROUP_CONCAT(u.profile_picture ORDER BY RAND() SEPARATOR ',')
                    FROM (
                        SELECT u.profile_picture
                        FROM tbl_event_attendance ea
                        JOIN tbl_user u ON ea.user_id = u.user_id
                        WHERE ea.event_id = e.event_id
                        AND ea.status = 'Registered'
                        LIMIT 4
                    ) AS u
                ),
                'total_attendees', (
                    SELECT COUNT(*)
                    FROM tbl_event_attendance
                    WHERE event_id = e.event_id
                    AND status = 'Registered'
                )
            ))
            FROM tbl_event e
            WHERE e.organization_id = o.organization_id
            AND e.status = 'Approved'
            AND e.start_date >= CURDATE()
            ORDER BY e.start_date ASC
            LIMIT 5
        ) AS upcoming_events,
        (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'role_name', er.role_title,
                'profile_picture', u.profile_picture
            ))
            FROM tbl_organization_members om
            JOIN tbl_executive_role er ON om.executive_role_id = er.executive_role_id
            JOIN tbl_user u ON om.user_id = u.user_id
            WHERE om.organization_id = o.organization_id
            AND om.member_type = 'Executive'
        ) AS officers
    FROM tbl_organization o
    ORDER BY o.category, o.name;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetUpcomingEvents(IN p_user_id VARCHAR(200))
BEGIN
    WITH UserOrganizations AS (
        SELECT organization_id 
        FROM tbl_organization_members 
        WHERE user_id = p_user_id
        
        UNION
        
        SELECT c.organization_id 
        FROM tbl_committee_members cm
        JOIN tbl_committee c ON cm.committee_id = c.committee_id
        WHERE cm.user_id = p_user_id
    )
    
    SELECT 
        e.event_id,
        e.title AS event_title,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.venue,
        o.name AS organization_name,
        o.logo AS organization_logo,
        (
            SELECT GROUP_CONCAT(profile_picture ORDER BY RAND() SEPARATOR ',')
            FROM (
                SELECT u.profile_picture
                FROM tbl_event_attendance ea
                JOIN tbl_user u ON ea.user_id = u.user_id
                WHERE ea.event_id = e.event_id
                AND ea.status = 'Registered'
                ORDER BY RAND()
                LIMIT 4
            ) AS random_attendees
        ) AS attendee_profile_pictures,
        (
            SELECT COUNT(*) 
            FROM tbl_event_attendance 
            WHERE event_id = e.event_id
            AND status = 'Registered'
        ) AS total_attendees
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    LEFT JOIN UserOrganizations uo ON e.organization_id = uo.organization_id
    WHERE e.status = 'Approved'
      AND e.start_date >= CURDATE()
      AND (
          e.is_open_to_all = TRUE
          OR uo.organization_id IS NOT NULL
      )
    ORDER BY e.start_date ASC, e.start_time ASC
    LIMIT 5;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetUserOrganization(IN p_user_id VARCHAR(200))
BEGIN
    SELECT DISTINCT
        o.organization_id,
        o.name AS organization_name,
        o.logo,
        COALESCE(
            GROUP_CONCAT(
                CASE 
                    WHEN om.member_type = 'Executive' THEN er.role_title
                    WHEN cm.role IS NOT NULL THEN CONCAT('Committee ', cm.role)
                    ELSE om.member_type
                END
                SEPARATOR ', '
            ),
            'Member'
        ) AS user_position
    FROM tbl_organization o
    LEFT JOIN tbl_organization_members om 
        ON o.organization_id = om.organization_id 
        AND om.user_id = p_user_id
    LEFT JOIN tbl_executive_role er 
        ON om.executive_role_id = er.executive_role_id
    LEFT JOIN tbl_committee_members cm 
        ON cm.user_id = p_user_id
        AND cm.committee_id IN (
            SELECT committee_id 
            FROM tbl_committee 
            WHERE organization_id = o.organization_id
        )
    WHERE om.user_id = p_user_id
       OR cm.user_id = p_user_id
    GROUP BY o.organization_id, o.name, o.logo
    ORDER BY o.name;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddCertificateTemplate(IN
    p_event_id INT,
    p_template_path VARCHAR(255),
    p_uploaded_by VARCHAR(200)
)
BEGIN
    INSERT INTO tbl_certificate_template (event_id, template_path, uploaded_by)
    VALUES (p_event_id, p_template_path, p_uploaded_by);

END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddGeneratedCertificate(IN
    p_event_id INT,
    p_user_id VARCHAR(200),
    p_template_id INT,
    p_certificate_path VARCHAR(255),
    p_verification_code VARCHAR(36)
)
BEGIN

    INSERT INTO tbl_event_certificate (event_id, user_id, template_id, certificate_path, verification_code)
    VALUES (p_event_id, p_user_id, p_template_id, p_certificate_path, p_verification_code);

END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetCertificateTemplate(IN
    p_event_id INT
)
BEGIN
    
    SELECT * FROM tbl_certificate_template WHERE event_id = p_event_id;
    
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEvaluationQuestions(IN p_event_id INT)
BEGIN
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'group_id', g.group_id,
            'group_title', g.group_title,
            'questions', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'question_id', q.question_id,
                        'question_text', q.question_text,
                        'question_type', q.question_type,
                        'is_required', q.is_required
                    )
                )
                FROM tbl_evaluation_question q
                WHERE q.group_id = g.group_id
            )
        )
    ) AS evaluation_form
    FROM tbl_evaluation_question_group g
    WHERE g.group_id IN (
        SELECT group_id 
        FROM tbl_event_evaluation_config 
        WHERE event_id = p_event_id
    )
    AND g.is_active = TRUE;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE SubmitEvaluation(IN p_json_data JSON)
BEGIN
    DECLARE v_evaluation_id INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_event_id INT;
    DECLARE v_question_count INT;
    DECLARE v_counter INT DEFAULT 0;
    DECLARE v_question_id INT;
    DECLARE v_answer TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Extract basic information
    SET v_user_id = JSON_UNQUOTE(JSON_EXTRACT(p_json_data, '$.user_id'));
    SET v_event_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_json_data, '$.event_id')) AS UNSIGNED);

    -- Create evaluation record
    INSERT INTO tbl_evaluation (event_id, user_id)
    VALUES (v_event_id, v_user_id);
    SET v_evaluation_id = LAST_INSERT_ID();

    -- Process Likert Scale Answers
    SET v_question_count = JSON_LENGTH(p_json_data, '$.likert_scale');
    WHILE v_counter < v_question_count DO
        SET v_question_id = CAST(
            JSON_UNQUOTE(JSON_EXTRACT(p_json_data, 
                CONCAT('$.likert_scale[', v_counter, '].question_id')))
            AS UNSIGNED
        );
        SET v_answer = JSON_UNQUOTE(JSON_EXTRACT(p_json_data, 
            CONCAT('$.likert_scale[', v_counter, '].answer')));
        
        INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value)
        VALUES (v_evaluation_id, v_question_id, v_answer);
        
        SET v_counter = v_counter + 1;
    END WHILE;

    -- Process Text Answers
    SET v_counter = 0;
    SET v_question_count = JSON_LENGTH(p_json_data, '$.text_answers');
    WHILE v_counter < v_question_count DO
        SET v_question_id = CAST(
            JSON_UNQUOTE(JSON_EXTRACT(p_json_data, 
                CONCAT('$.text_answers[', v_counter, '].question_id')))
            AS UNSIGNED
        );
        SET v_answer = JSON_UNQUOTE(JSON_EXTRACT(p_json_data, 
            CONCAT('$.text_answers[', v_counter, '].answer')));
        
        INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value)
        VALUES (v_evaluation_id, v_question_id, v_answer);
        
        SET v_counter = v_counter + 1;
    END WHILE;

    COMMIT;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetUserPermissions(IN p_user_id VARCHAR(200))
BEGIN
    SELECT JSON_OBJECT(
        'f_name', u.f_name,
        'l_name', u.l_name,
        'role', r.role_name,
        'email', u.email,
        'program_id', p.program_id,
        'program_name', p.name,
        'permissions', COALESCE(
            (
                SELECT JSON_ARRAYAGG(permission_name)
                FROM (
                    SELECT DISTINCT permission_name
                    FROM (
                        -- Base role permissions
                        SELECT p.permission_name
                        FROM tbl_role_permission rp
                        JOIN tbl_permission p ON rp.permission_id = p.permission_id
                        WHERE rp.role_id = u.role_id

                        UNION ALL

                        -- Executive role permissions through ranks
                        SELECT p.permission_name
                        FROM tbl_organization_members om
                        JOIN tbl_executive_role er ON om.executive_role_id = er.executive_role_id
                        JOIN tbl_rank_permission rp ON er.rank_id = rp.rank_id
                        JOIN tbl_permission p ON rp.permission_id = p.permission_id
                        WHERE om.user_id = u.user_id

                        UNION ALL

                        -- Committee role permissions
                        SELECT p.permission_name
                        FROM tbl_committee_members cm
                        JOIN tbl_committee c ON cm.committee_id = c.committee_id
                        JOIN tbl_committee_role cr ON c.committee_id = cr.committee_id
                        JOIN tbl_committee_role_permission crp ON cr.committee_role_id = crp.committee_role_id
                        JOIN tbl_permission p ON crp.permission_id = p.permission_id
                        WHERE cm.user_id = u.user_id
                    ) AS all_permissions
                ) AS distinct_permissions
            ),
            JSON_ARRAY()
        ),
        'organizations', COALESCE(
            (
                SELECT JSON_ARRAYAGG(JSON_OBJECT(
                    'name', orgs.name,
                    'logo', orgs.logo,
                    'status', orgs.status
                ))
                FROM (
                    SELECT o.name, o.logo, o.status
                    FROM tbl_organization o
                    WHERE o.adviser_id = u.user_id

                    UNION

                    SELECT o.name, o.logo, o.status
                    FROM tbl_organization_members om
                    JOIN tbl_renewal_cycle rc ON om.organization_id = rc.organization_id 
                        AND om.cycle_number = rc.cycle_number
                    JOIN tbl_organization o ON om.organization_id = o.organization_id
                    WHERE om.user_id = u.user_id
                ) AS orgs
                GROUP BY orgs.name, orgs.logo, orgs.status
            ),
            JSON_ARRAY()
        )
    ) AS user_info
    FROM tbl_user u
    JOIN tbl_role r ON u.role_id = r.role_id
    LEFT JOIN tbl_program p ON u.program_id = p.program_id
    WHERE u.user_id = p_user_id;
END $$
DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CreateUser(
    IN p_user_id VARCHAR(200),
    IN p_f_name VARCHAR(50),
    IN p_l_name VARCHAR(50),
    IN p_email VARCHAR(50)
)
BEGIN
    DECLARE student_role_id INT;
    
    SELECT role_id INTO student_role_id 
    FROM tbl_role 
    WHERE LOWER(role_name) = 'student';
    
    INSERT INTO tbl_user (
        user_id,
        f_name,
        l_name,
        email,
        role_id
    ) VALUES (
        p_user_id,
        p_f_name,
        p_l_name,
        p_email,
        student_role_id
    );
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE HandleLogin(
    IN p_azure_sub VARCHAR(200),
    IN p_email VARCHAR(50),
    IN p_f_name VARCHAR(50),
    IN p_l_name VARCHAR(50)
)
BEGIN
    DECLARE v_existing_user_id VARCHAR(200);
    DECLARE v_student_role_id INT;
    DECLARE v_current_status ENUM('Pending', 'Active', 'Suspended');
    DECLARE v_current_role_id INT;

    SELECT role_id INTO v_student_role_id 
    FROM tbl_role 
    WHERE LOWER(role_name) = 'student';

    SELECT user_id, status, role_id 
    INTO v_existing_user_id, v_current_status, v_current_role_id
    FROM tbl_user 
    WHERE email = p_email;

    IF v_existing_user_id IS NOT NULL THEN

        IF v_current_status = 'Pending' AND v_current_role_id != v_student_role_id THEN

            UPDATE tbl_user 
            SET user_id = p_azure_sub,
                f_name = p_f_name,
                l_name = p_l_name,
                status = 'Active'
            WHERE email = p_email;
        ELSE
            IF v_existing_user_id != p_azure_sub THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Account conflict detected';
            END IF;
        END IF;
    ELSE

        INSERT INTO tbl_user (
            user_id,
            f_name,
            l_name,
            email,
            role_id,
            status
        ) VALUES (
            p_azure_sub,
            p_f_name,
            p_l_name,
            p_email,
            v_student_role_id,
            'Active'
        );
    END IF;

    CALL GetUserPermissions(p_azure_sub);
END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetManagedAccounts()
BEGIN
    DECLARE student_role_id INT;
    
    SELECT role_id INTO student_role_id 
    FROM tbl_role 
    WHERE LOWER(role_name) = 'student';

    SELECT JSON_OBJECT(
        'accounts', COALESCE(
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'user_id', u.user_id,
                    'name', CONCAT(u.f_name, ' ', u.l_name),
                    'email', u.email,
                    'program', p.name,
                    'role', r.role_name,
                    'status', u.status,
                    'created_at', u.created_at,
                    'updated_at', u.updated_at
                )
             )
             FROM tbl_user u
             JOIN tbl_role r ON u.role_id = r.role_id
             LEFT JOIN tbl_program p ON u.program_id = p.program_id
             WHERE u.role_id != student_role_id
               AND u.status = 'Active'
            ), 
            JSON_ARRAY()
        ),
        'pending_accounts', COALESCE(
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'user_id', u.user_id,
                    'name', CONCAT(u.f_name, ' ', u.l_name),
                    'email', u.email,
                    'program', p.name,
                    'role', r.role_name,
                    'status', u.status,
                    'created_at', u.created_at,
                    'updated_at', u.updated_at
                )
             )
             FROM tbl_user u
             JOIN tbl_role r ON u.role_id = r.role_id
             LEFT JOIN tbl_program p ON u.program_id = p.program_id
             WHERE u.role_id != student_role_id
               AND u.status = 'Pending'
            ), 
            JSON_ARRAY()
        ),
        'archive_accounts', COALESCE(
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'user_id', u.user_id,
                    'name', CONCAT(u.f_name, ' ', u.l_name),
                    'program', p.name,
                    'email', u.email,
                    'role', r.role_name,
                    'status', u.status,
                    'created_at', u.created_at,
                    'archived_at', u.archived_at,
                    'updated_at', u.updated_at
                )
             )
             FROM tbl_user u
             JOIN tbl_role r ON u.role_id = r.role_id
             LEFT JOIN tbl_program p ON u.program_id = p.program_id
             WHERE u.role_id != student_role_id
               AND u.status = 'Archive'
            ),
            JSON_ARRAY()
        ),
        'programs', COALESCE(
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'program_id', p.program_id,
                    'program_name', p.name
                )
             )
             FROM tbl_program p),
            JSON_ARRAY()
        ),
        'roles', COALESCE(
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'role_id', r.role_id,
                    'role_name', r.role_name
                )
             )
             FROM tbl_role r
             WHERE r.role_id != student_role_id),
            JSON_ARRAY()
        )
    ) AS result;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddManagedAccount(
    IN p_email VARCHAR(100),
    IN p_role_name VARCHAR(100),
    IN p_program_id INT
)
BEGIN
    DECLARE v_role_id INT;
    DECLARE v_existing_user INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get role ID from role name
    SELECT role_id INTO v_role_id 
    FROM tbl_role 
    WHERE role_name = p_role_name;

    IF v_role_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid role specified';
    END IF;

    -- Check if user exists
    SELECT COUNT(*) INTO v_existing_user
    FROM tbl_user 
    WHERE email = p_email;

    IF v_existing_user > 0 THEN
        -- Update existing account
        UPDATE tbl_user
        SET role_id = v_role_id,
            program_id = p_program_id
        WHERE email = p_email;

        -- Log the update
        INSERT INTO tbl_logs (
            user_id,
            action,
            type
        ) VALUES (
            (SELECT user_id FROM tbl_user WHERE email = p_email),
            'Updated managed account',
            'account'
        );
    ELSE
        -- Create new pending account
        INSERT INTO tbl_user (
            user_id,
            email,
            role_id,
            program_id,
            status
        ) VALUES (
            CONCAT('pending-', UUID()),
            p_email,
            v_role_id,
            p_program_id,
            'Pending'
        );

        -- Log the creation
        INSERT INTO tbl_logs (
            user_id,
            action,
            type
        ) VALUES (
            (SELECT user_id FROM tbl_user WHERE email = p_email),
            'Created managed account',
            'account'
        );
    END IF;

    COMMIT;
END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE UpdateManagedAccount(
    IN p_user_id VARCHAR(200),
    IN p_email VARCHAR(100),
    IN p_role_name VARCHAR(100),
    IN p_program_name VARCHAR(100),
    IN p_status ENUM('Active', 'Pending', 'Archive')
)
BEGIN
    DECLARE v_role_id INT;
    DECLARE v_program_id INT;

    -- Get role ID from role name
    SELECT role_id INTO v_role_id 
    FROM tbl_role 
    WHERE role_name = p_role_name;

    IF v_role_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid role specified';
    END IF;

    -- Set program_id to NULL if program_name is 'not_applicable', else get program_id
    IF p_program_name = 'not_applicable' THEN
        SET v_program_id = NULL;
    ELSE
        SELECT program_id INTO v_program_id
        FROM tbl_program
        WHERE name = p_program_name;

        IF v_program_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid program specified';
        END IF;
    END IF;

    -- Update the account, including email
    UPDATE tbl_user
    SET 
        email = p_email,
        role_id = v_role_id,
        program_id = v_program_id,
        status = p_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;

    -- Log the update
    INSERT INTO tbl_logs (
        user_id,
        action,
        type
    ) VALUES (
        p_user_id,
        'Updated managed account',
        'account'
    );
END $$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE DeleteManagedAccount(
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE user_count INT;
    DECLARE v_user_id VARCHAR(200);
    
    -- Check if the user exists
    SELECT COUNT(*) INTO user_count
    FROM tbl_user 
    WHERE email = p_email;

    IF user_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found';
    ELSE
        -- Get the user_id to log the action properly
        SELECT user_id INTO v_user_id
        FROM tbl_user
        WHERE email = p_email;

        -- Archive the user
        UPDATE tbl_user
        SET 
            status = 'Archive',
            archived_at = CURRENT_TIMESTAMP
        WHERE email = p_email;

        -- Log the archiving
        INSERT INTO tbl_logs (
            user_id,
            action,
            type
        ) VALUES (
            v_user_id,
            'Archived managed account',
            'account'
        );
    END IF;
END $$

DELIMITER ;

    -- Unarchive account
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE UnarchiveManagedAccount(
    IN p_user_id VARCHAR(200)
)
BEGIN
    DECLARE user_count INT;

    -- Check if user exists
    SELECT COUNT(*) INTO user_count
    FROM tbl_user 
    WHERE user_id = p_user_id;

    IF user_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found';
    ELSE
        -- Unarchive user
        UPDATE tbl_user
        SET 
            status = 'Active',
            archived_at = NULL
        WHERE user_id = p_user_id;

        -- Log the action using the correct user_id
        INSERT INTO tbl_logs (
            user_id,
            action,
            type
        ) VALUES (
            p_user_id,
            'Unarchived managed account',
            'account'
        );
    END IF;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetRequirements()
BEGIN 

	SELECT * FROM tbl_application_requirement;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddRequirement(IN
	p_requirement_name VARCHAR(255),
    p_file_path VARCHAR(255),
    p_created_by VARCHAR(200)
)
BEGIN 

	INSERT INTO tbl_application_requirement(requirement_name, file_path, created_by) VALUES(p_requirement_name, p_file_path, p_created_by);
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetSpecificRequirement(IN
	p_requirement_id INT
)
BEGIN 

	SELECT * FROM tbl_application_requirement WHERE requirement_id = p_requirement_id;
END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE DeleteRequirement(
    IN p_requirement_id INT
)
BEGIN
    DELETE FROM tbl_application_requirement WHERE requirement_id = p_requirement_id;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE UpdateRequirement(IN
	p_requirement_id INT,
    p_requirement_name VARCHAR(255),
    p_file_path VARCHAR(255)
)
BEGIN
	UPDATE tbl_application_requirement SET requirement_name = p_requirement_name, file_path = p_file_path;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddApplicationPeriod(IN
	p_start_date DATE,
    p_end_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_created_by VARCHAR(200)
)
BEGIN
	INSERT INTO tbl_application_period
    (
    start_date, 
    end_date, 
    start_time, 
    end_time,
    created_by)
    VALUES
    (p_start_date, 
    p_end_date, 
    p_start_time, 
    p_end_time,
    p_created_by
    );
END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetActiveApplicationPeriod()
BEGIN
  DECLARE currentDate DATE;
  DECLARE currentTime TIME;
  
  SET currentDate = CURDATE();
  SET currentTime = CURTIME();

  SELECT *
  FROM tbl_application_period
  WHERE is_active = 1
    AND currentDate BETWEEN start_date AND end_date
    AND (
      (currentDate > start_date AND currentDate < end_date) OR
      (currentDate = start_date AND currentTime >= start_time) OR
      (currentDate = end_date AND currentTime <= end_time)
    )
  ORDER BY created_at DESC
  LIMIT 1;
END $$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE UpdateApplicationPeriod()
BEGIN
  UPDATE tbl_application_period
  SET is_active = 0
  WHERE is_active = 1;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE InitiateApprovalProcess(IN p_application_id INT)
BEGIN
    DECLARE v_org_id INT;
    DECLARE v_program_id INT;
    DECLARE v_adviser_id VARCHAR(200);
    DECLARE v_step INT DEFAULT 1;
    DECLARE v_role_name VARCHAR(50);
    DECLARE v_approver_id VARCHAR(200);
    DECLARE v_role_id INT;
    
    -- Get organization and program details
    SELECT o.organization_id, o.base_program_id, o.adviser_id
    INTO v_org_id, v_program_id, v_adviser_id
    FROM tbl_application a
    JOIN tbl_organization o ON a.organization_id = o.organization_id
    WHERE a.application_id = p_application_id;

    -- Create approval steps
    WHILE v_step <= 5 DO
        BEGIN
            -- Determine role for current step
            SET v_role_name = CASE v_step
                WHEN 1 THEN 'Adviser'
                WHEN 2 THEN 'Program Chair'
                WHEN 3 THEN 'Dean'
                WHEN 4 THEN 'Academic Director'
                WHEN 5 THEN 'SDAO'
            END;

            -- Get role ID from tbl_role
            SELECT role_id INTO v_role_id 
            FROM tbl_role 
            WHERE role_name = v_role_name;

            -- Special handling for first step (organization adviser)
            IF v_step = 1 THEN
                -- Validate adviser exists and has correct role
                IF NOT EXISTS (
                    SELECT 1 FROM tbl_user 
                    WHERE user_id = v_adviser_id 
                    AND role_id = v_role_id
                ) THEN
                    SIGNAL SQLSTATE '45000' 
                    SET MESSAGE_TEXT = 'Organization adviser must have Adviser role';
                END IF;
                
                SET v_approver_id = v_adviser_id;
            ELSE
                -- Find approver based on role and program
                IF v_step = 2 THEN
                    -- Program Chair needs program-specific user
                    SELECT u.user_id INTO v_approver_id
                    FROM tbl_user u
                    WHERE u.role_id = v_role_id
                    AND u.program_id = v_program_id
                    LIMIT 1;
                ELSE
                    -- Global roles for steps 3-5
                    SELECT u.user_id INTO v_approver_id
                    FROM tbl_user u
                    WHERE u.role_id = v_role_id
                    LIMIT 1;
                END IF;
                
                IF v_approver_id IS NULL THEN
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No approver_Found';
                END IF;
            END IF;

            -- Create approval step
            INSERT INTO tbl_approval_process (
                organization_id,
                period_id,
                approver_id,
                approval_role_id,
                application_type,
                status,
                step
            )
            SELECT 
                v_org_id,
                a.period_id,
                v_approver_id,
                v_role_id,
                a.application_type,
                'Pending',
                v_step
            FROM tbl_application a
            WHERE a.application_id = p_application_id;
            
            SET v_step = v_step + 1;
        END;
    END WHILE;

    -- Update application status
    UPDATE tbl_application 
    SET status = 'pending'
    WHERE application_id = p_application_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CreateOrganizationApplication(
    IN p_organization JSON,
    IN p_executives JSON,
    IN p_requirements JSON,
    IN p_user_id VARCHAR(200)
    )
BEGIN
    DECLARE v_organization_id INT;
    DECLARE v_program_id INT;
    DECLARE v_period_id INT;
    DECLARE v_application_id INT;
    DECLARE v_president_id VARCHAR(200);
    DECLARE v_org_name VARCHAR(100);
    DECLARE v_logo_filename VARCHAR(255);
    DECLARE v_sanitized_name VARCHAR(100);
    DECLARE i INT DEFAULT 0;
    DECLARE v_requirement_count INT;
    DECLARE v_rank_number INT;
    DECLARE v_rank_id INT;
    DECLARE v_error_msg VARCHAR(255);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get user's program
    SELECT program_id INTO v_program_id 
    FROM tbl_user 
    WHERE user_id = p_user_id;

    IF v_program_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User program not found';
    END IF;

    -- Create organization
    INSERT INTO tbl_organization (
        adviser_id,
        name,
        description,
        logo,
        base_program_id,
        status,
        membership_fee_type,
        membership_fee_amount,
        is_recruiting,
        is_open_to_all_courses,
        category
    ) VALUES (
        p_user_id,
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_name')),
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_description')),
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_logo')),
        v_program_id,
        'Pending',
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.fee_duration')),
        CAST(JSON_EXTRACT(p_organization, '$.fee_amount') AS DECIMAL(10,2)),
        FALSE,
        FALSE,
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.category'))
    );

    SET v_organization_id = LAST_INSERT_ID();
    SET v_org_name = JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_name'));
    SET v_logo_filename = JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_logo'));
    SET v_sanitized_name = LOWER(REPLACE(v_org_name, ' ', '-'));

    -- First pass: Create users and identify president
    SET i = 0;
    WHILE i < JSON_LENGTH(p_executives) DO
        BEGIN
            DECLARE v_fname VARCHAR(50);
            DECLARE v_lname VARCHAR(50);
            DECLARE v_role VARCHAR(100);
            DECLARE v_email VARCHAR(100);
            
            SET v_fname = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].f_name')));
            SET v_lname = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].l_name')));
            SET v_role = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].role_name')));
            SET v_email = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].nu_email')));
            SET v_rank_number = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].rank_number'))) AS UNSIGNED);
            
            -- Validate rank exists
            IF NOT EXISTS (
                SELECT 1 
                FROM tbl_executive_rank 
                WHERE rank_level = v_rank_number
            ) THEN
                SET v_error_msg = CONCAT('Invalid rank number: ', v_rank_number);
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
            END IF;

            -- Check/create user
            INSERT IGNORE INTO tbl_user (
                user_id,
                f_name,
                l_name,
                email,
                program_id,
                role_id,
                status
            ) VALUES (
                v_email,
                v_fname,
                v_lname,
                v_email,
                v_program_id,
                1,
                'Pending'
            );

            -- Identify president
            IF v_rank_number = 5 THEN
                IF v_president_id IS NOT NULL THEN
                    SET v_error_msg = 'Multiple presidents detected (multiple rank 5 entries)';
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
                END IF;
                SET v_president_id = v_email;
            END IF;

            SET i = i + 1;
        END;
    END WHILE;

    -- Validate president exists
    IF v_president_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organization must have one member with rank 5 (president equivalent)';
    END IF;

    -- Create renewal cycle after users exist
    INSERT INTO tbl_renewal_cycle (
        organization_id,
        cycle_number,
        president_id
    ) VALUES (
        v_organization_id,
        1,
        v_president_id
    );

    -- Second pass: Create executive roles
    SET i = 0;
    WHILE i < JSON_LENGTH(p_executives) DO
        BEGIN
            DECLARE v_fname VARCHAR(50);
            DECLARE v_lname VARCHAR(50);
            DECLARE v_role VARCHAR(100);
            DECLARE v_email VARCHAR(100);
            DECLARE v_exec_role_id INT;
            
            SET v_fname = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].f_name')));
            SET v_lname = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].l_name')));
            SET v_role = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].role_name')));
            SET v_email = JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].nu_email')));
            SET v_rank_number = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_executives, CONCAT('$[', i, '].rank_number'))) AS UNSIGNED);

            SELECT rank_id INTO v_rank_id 
            FROM tbl_executive_rank 
            WHERE rank_level = v_rank_number;

            -- Create executive role
            INSERT INTO tbl_executive_role (
                organization_id,
                cycle_number,
                role_title,
                rank_id
            ) VALUES (
                v_organization_id,
                1,
                v_role,
                v_rank_id
            );
            
            SET v_exec_role_id = LAST_INSERT_ID();
            
            INSERT INTO tbl_organization_members (
                organization_id,
                cycle_number,
                user_id,
                member_type,
                executive_role_id
            ) VALUES (
                v_organization_id,
                1,
                v_email,
                'Executive',
                v_exec_role_id
            );

            SET i = i + 1;
        END;
    END WHILE;

    -- Get active application period
    SELECT period_id INTO v_period_id 
    FROM tbl_application_period 
    WHERE is_active = TRUE 
    ORDER BY created_at DESC 
    LIMIT 1;

    IF v_period_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active application period';
    END IF;

    -- Create application
    INSERT INTO tbl_application (
        organization_id,
        cycle_number,
        application_type,
        period_id,
        applicant_user_id,
        status
    ) VALUES (
        v_organization_id,
        1,
        'new',
        v_period_id,
        p_user_id,
        'pending'
    );

    SET v_application_id = LAST_INSERT_ID();

    CALL InitiateApprovalProcess(v_application_id);
    -- Handle requirements
    SET v_requirement_count = JSON_LENGTH(p_requirements);
    SET i = 0;
    WHILE i < v_requirement_count DO
        BEGIN
            DECLARE v_req_id INT;
            DECLARE v_file_path VARCHAR(255);
            
            SET v_req_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].requirement_id'))) AS UNSIGNED);
            SET v_file_path = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].requirement_path')));
            
            INSERT INTO tbl_organization_requirement_submission (
                application_id,
                requirement_id,
                cycle_number,
                organization_id,
                file_path,
                submitted_by
            ) VALUES (
                v_application_id,
                v_req_id,
                1,
                v_organization_id,
                v_file_path,
                p_user_id
            );

            SET i = i + 1;
        END;
    END WHILE;

    COMMIT;

    SELECT 
        v_organization_id AS organization_id,
        v_application_id AS application_id,
        v_sanitized_name AS directory_name,
        CONCAT(v_sanitized_name, '/logo/', v_logo_filename) AS logo_path,
        CONCAT(v_sanitized_name, '/requirements/') AS requirements_dir;
END$$
DELIMITER ;

    -- For all events
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEvents()
BEGIN
    SELECT 
        e.event_id,
        e.title,
        e.description,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.capacity,
        e.certificate,
        e.fee,
        e.is_open_to_all,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.venue,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id;
END $$

DELIMITER ;

    -- For viewing specific details of an event
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventById(IN p_event_id INT)
BEGIN
    SELECT 
        e.event_id,
        e.title,
        e.description,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.capacity,
        e.certificate,
        e.fee,
        e.is_open_to_all,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.venue,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE e.event_id = p_event_id;
END $$

DELIMITER ;

    -- Get event by status
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventsByStatus(IN p_status VARCHAR(20))
BEGIN
    SELECT 
        e.event_id,
        e.title,
        e.description,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.capacity,
        e.certificate,
        e.fee,
        e.is_open_to_all,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.venue,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE e.status = p_status;
END $$

DELIMITER ;

-- INDEXES

CREATE INDEX idx_org_members_user ON tbl_organization_members(user_id);
CREATE INDEX idx_event_program ON tbl_event_course(program_id);

CREATE INDEX idx_org_members ON tbl_organization_members(organization_id, user_id);
CREATE INDEX idx_committee_org ON tbl_committee(organization_id);
CREATE INDEX idx_committee_members_user ON tbl_committee_members(user_id);

CREATE INDEX idx_active_end_datetime 
ON tbl_application_period(is_active, end_date, end_time);

-- EVENTS

DELIMITER $$
CREATE DEFINER='admin'@'%' EVENT ev_disable_expired_periods
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
  UPDATE tbl_application_period
  SET is_active = 0
  WHERE is_active = 1
    AND (
      end_date < CURDATE()
      OR (end_date = CURDATE() AND end_time < CURTIME())
    );
END $$

DELIMITER ;

-- SAMPLE DATAS
INSERT INTO tbl_role(role_name, is_approver, hierarchy_order)
VALUES("STUDENT",0,null), 
("ADVISER",1,1),
("PROGRAMCHAIR",1,2),
("SDAO",1,5),
("DEAN",1,3),
("ACADEMICDIRECTOR",1,4);


INSERT INTO tbl_permission(permission_name)
VALUES("CREATE_EVENT"),
("UPDATE_EVENT"),
("DELETE_EVENT"),
("VIEW_EVENT"),
("REGISTER_EVENT"),
("APPLY_ORGANIZATION"),
("APPROVE_ORGANIZATION"),
("ARCHIVE_ORGANIZATION"),
("VIEW_ORGANIZATION"),
("MANAGE_ACCOUNT"),
("CREATE_COMMITTEE"),
("UPDATE_COMMITTEE"),
("DELETE_COMMITTEE"),
("VIEW_COMMITTEE"),
("MANAGE_REQUIREMENTS"),
("VIEW_APPLICATION_FORM"),
("MANAGE_APPLICATIONS"),
("CREATE_EVALUATION"),
("UPDATE_EVALUATION"),
("DELETE_EVALUATION"),
("VIEW_EVALUATION"),
("VIEW_LOGS"),
("WEB_ACCESS");

INSERT INTO tbl_role_permission (role_id, permission_id) 
VALUES
(4,1),
(4,2),
(4,3),
(4,4),
(4,9),
(4,10),
(4,15),
(4,22),
(4,23),
(2,6),
(2,9),
(2,23);


INSERT INTO tbl_program (name, description) VALUES 
("Bachelor of Science in Information Technology", "BSIT"),
("Bachelor of Science in Computer Science", "BSCS");

INSERT INTO tbl_user (user_id, f_name, l_name, email, program_id, role_id) VALUES
("900f929ec408cb4", "Benson","Javier","benson09.javier@outlook.com", 1 , 1),
("5fb95ed0a0d20daf", "Geraldine","Aris","arisgeraldine@outlook.com", 1, 1),
("6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0", "Benson","Javier","javierbb@students.nu-dasma.edu.ph",null,4),
("cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k", "Carl Roehl", "Falcon", "falconcs@students.nu-dasma.edu.ph", null, 4),
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Samantha Joy", "Madrunio", "madruniosm@students.nu-dasma.edu.ph", 1, 2),
("_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU", "Geraldine", "Aris", "arisgc@students.nu-dasma.edu.ph",null, 4);

INSERT INTO tbl_organization (adviser_id, name, description, base_program_id, status, membership_fee_type, membership_fee_amount, is_recruiting, is_open_to_all_courses) VALUES
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Computer Society", "This is the computer society", 1, "Approved", "Whole Academic Year", 500, 0, 0),
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Isite","This is Isite", 2, "Approved", "Whole Academic Year", 500,0,0);

-- INSERT INTO tbl_event (
--   event_id, title, description, date, start_time, end_time, capacity,
--   certificate, fee, is_open_to_all, organization_id, status, type, user_id,
--   venue, created_at
-- ) VALUES
-- (1001, 'Innovation Pitch Fest', 'A competition for pitching new ideas', '2025-06-10', '09:00:00', '15:00:00', 100, 'Participation Certificate', 50, 1, 1, 'Approved', 'Paid', 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'NU Hall A', '2025-05-01 08:00:00'),

-- (1002, 'Groove Jam 2025', 'Annual inter-school dance battle', '2025-07-20', '13:00:00', '19:00:00', 300, 'Winner + Participation', 0, 1, 2, 'Approved', 'Free', 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Open Grounds', '2025-05-05 10:30:00'),

-- (1003, 'Hack-It-Out', '24-hour Hackathon for IT majors', '2025-08-05', '08:00:00', '08:00:00', 60, 'Certificate + Swag', 200, 0, 1, 'Pending', 'Paid', 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Tech Lab 101', '2025-05-12 15:45:00'),

-- (1004, 'Earth Hour Rally', 'Tree planting and cleanup event', '2025-06-15', '06:30:00', '10:30:00', 150, 'Eco Warrior Badge', 0, 1, 2, 'Approved', 'Free', 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Community Park', '2025-05-15 09:00:00'),

-- (1005, 'E-Sports Showdown', 'Inter-university e-sports competition', '2025-07-01', '10:00:00', '18:00:00', 500, 'Winner Certificate', 100, 1, 1, 'Archived', 'Paid', 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Auditorium', '2025-05-10 13:15:00');

-- INSERT INTO tbl_executive_role(organization_id, role_title)VALUES
-- (2,"President");

-- INSERT INTO tbl_organization_members(organization_id,user_id, member_type, executive_role_id)
-- VALUES (1, "900f929ec408cb4", "Member",null),
-- (2, "86533891asdvf", "Executive",null),
-- (2, "5fb95ed0a0d20daf","Member",1);

-- 

INSERT INTO tbl_executive_rank (rank_level, default_title, description) VALUES
(5, 'President', 'Highest authority with full permissions'),
(4, 'Vice President', 'Second-in-command'),
(3, 'Secretary', 'Administrative lead'),
(2, 'Treasurer', 'Financial manager'),
(1, 'Officer', 'General executive member');

-- QUESTIONS

INSERT INTO tbl_evaluation_question_group (group_title, group_description, is_active)
VALUES 
('Activity: Meeting/Seminar/Conference/Workshop/Quiz Bee/Competition/Sport fest, etc.', 'Question about activities', TRUE),
('About the Speaker/Resource person', 'Feedback about event speakers/presenters', TRUE),
('Meals', 'Feedback about meals', TRUE),
('Handouts', 'Feedback about handouts', TRUE),
('Transportation', 'Feedback about transportation', TRUE),
('Comments and Suggestions', 'Feedback about the whole event', TRUE);

INSERT INTO tbl_evaluation_question (question_text, question_type, group_id, is_required)
VALUES
('Is the activity relevant/important to you?', 'likert_4', 1, TRUE),
('Is the program relevant to the course/you’re in?', 'likert_4', 1, TRUE),
('Were the objectives clear and communicated before the activity?', 'likert_4', 1, TRUE),
('Were the objectives met by the activity?', 'likert_4', 1, TRUE),
('Was the venue proper for this kind of activity?', 'likert_4', 1, TRUE),
('Did the activity start and end on time?', 'likert_4', 1, TRUE),
('Did the organizers maintain an orderly environment all throughout the activity?', 'likert_4', 1, TRUE),
('Was the event/activity well-advertised/properly announce?', 'likert_4', 1, TRUE),
('Would you recommend this activity to your classmates/friends?', 'likert_4', 1, TRUE),
('Do you want an activity like this to happen more often?', 'likert_4', 1, TRUE),
('Overall evaluation', 'likert_4', 1, TRUE),
('Was the speaker well-prepared and knowledgeable on the topic?', 'likert_4', 2, TRUE),
('Did the speaker use different and appropriate methods in delivering the topic?', 'likert_4', 2, TRUE),
('Was the speaker able to connect with the audience and catch their attention?', 'likert_4', 2, TRUE),
('Were the meals/snacks provided enough to fill you?', 'likert_4', 3, TRUE),
('Did the meals/snacks have a pleasant taste?', 'likert_4', 3, TRUE),
('Are the handouts provided useful?', 'likert_4', 4, TRUE),
('Is the printing of the handouts clear?', 'likert_4', 4, TRUE),
('Did you feel safe during the travel to the venue?', 'likert_4', 5, TRUE),
('Did you feel that the transportation provided is in good running condition?', 'likert_4', 5, TRUE),
('Did you feel safe with the driver’s skills?', 'likert_4', 5, TRUE),
('What important knowledge or information did you gain from this activity?', 'textbox', 6, TRUE),
('What did you like most about the activity?', 'textbox', 6, TRUE),
('What did you like least about the activity?', 'textbox', 6, TRUE),
('Any other comments/suggestions for further improvement the activity?', 'textbox', 6, TRUE);

-- REQUIREMENTS


INSERT INTO tbl_application_requirement(
requirement_name, 
is_applicable_to, 
file_path, 
created_by, 
created_at, 
updated_at
) 
VALUES
('Letter of Intent', 'new', 'requirement-1747711120933-Letter-of-Intent.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:18:40', '2025-05-20 11:18:40'),
('Student Org Application Form', 'new', 'requirement-1747711141257-ACO-SA-F-002Student-Org-Application-Form.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:01', '2025-05-20 11:19:01'),
('By Laws of the Organization', 'new', 'requirement-1747711157238-Constitution-and-ByLaws.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:17', '2025-05-20 11:19:17'),
('List of Officers/Founders', 'new', 'requirement-1747711169050-List-of-Officers-and-Founders.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:29', '2025-05-20 11:19:29'),
('Letter from the College Dean', 'new', 'requirement-1747711179629-Letter-from-the-College-Dean.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:39', '2025-05-20 11:19:39'),
('List of Members', 'new', 'requirement-1747711196157-List-of-Members.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:56', '2025-05-20 11:19:56'),
('Latest Certificate of Grades of Officers', 'new', 'requirement-1747711230696-Latest-Certificate-of-Grades-of-Officers.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:20:30', '2025-05-20 11:20:30'),
('Biodata/CV of Officers', 'new', 'requirement-1747711248943-CV-of-Officers.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:20:48', '2025-05-20 11:20:48'),
('List of Proposed Projects with Proposed Budget for the AY', 'new', 'requirement-1747711260498-List-of-Proposed-Project-with-Proposed-Budget.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:21:00', '2025-05-20 11:21:00');

-- INSERT INTO tbl_logs (
--     user_id,
--     timestamp,
--     action,
--     redirect_url,
--     file_path,
--     meta_data,
--     type
-- ) VALUES
-- -- Sample 1: File upload with redirect and metadata
-- ('USR00001', CURRENT_TIMESTAMP, 'Uploaded organization logo',
--  '/organizations/NUD/details',
--  '["/uploads/logos/nud_logo.png"]',
--  '{"org_id": "NUD"}',
--  'file_upload'),

-- -- Sample 2: Info log with redirect only
-- ('USR00002', CURRENT_TIMESTAMP, 'Viewed event details',
--  '/events/45',
--  NULL,
--  '{"event_id": 45, "view_mode": "admin"}',
--  'info'),

-- -- Sample 3: Error log without redirect
-- ('USR00003', CURRENT_TIMESTAMP, 'Failed to submit event proposal due to missing requirements',
--  NULL,
--  NULL,
--  '{"attempted_event_id": 50}',
--  'error'),

-- -- Sample 4: System-generated log with no user
-- ('SYSTEM', CURRENT_TIMESTAMP, 'Daily analytics summary generated',
--  '/analytics/summary/daily',
--  NULL,
--  '{"records_processed": 932}',
--  'system');

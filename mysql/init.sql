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
    role_id INT NOT NULL, -- fixed typo
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
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    base_program_id INT NULL, -- NULL meaning open to all
    logo VARCHAR(255),
    status ENUM('Pending', 'Approved', 'Rejected', 'Renewal', 'Archived') DEFAULT 'Pending',
    membership_fee_type ENUM('Per Term', 'Whole Academic Year',"Free") NOT NULL DEFAULT 'Free',
    category ENUM('Co-Curricular Organization', 'Extra Curricular Organization') DEFAULT 'Co-Curricular Organization',
    membership_fee_amount DECIMAL(10,2) NULL,
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

CREATE TABLE tbl_membership_application (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by VARCHAR(200),
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id, cycle_number) 
        REFERENCES tbl_renewal_cycle(organization_id, cycle_number),
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id),
    FOREIGN KEY (reviewed_by) REFERENCES tbl_user(user_id)
);

-- Custom Questions Configuration
CREATE TABLE tbl_membership_question (
    question_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('text', 'multiple_choice', 'checkbox', 'file_upload') 
        DEFAULT 'text',
    is_required BOOLEAN DEFAULT TRUE,
    options JSON NULL,  -- For multiple choice options
    FOREIGN KEY (organization_id, cycle_number) 
        REFERENCES tbl_renewal_cycle(organization_id, cycle_number)
);

-- Application Responses
CREATE TABLE tbl_membership_response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    question_id INT NOT NULL,
    response_value TEXT NOT NULL,
    FOREIGN KEY (application_id) 
        REFERENCES tbl_membership_application(application_id),
    FOREIGN KEY (question_id) 
        REFERENCES tbl_membership_question(question_id)
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

-- CREATE TABLE tbl_membership_fees(
--     fee_id INT AUTO_INCREMENT PRIMARY KEY,
--     organization_id INT NOT NULL,
--     cycle_number INT NOT NULL,
--     user_id VARCHAR(200) NOT NULL,
--     amount DECIMAL(10,2) NOT NULL,
--     paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number) ON DELETE CASCADE,
--     FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON UPDATE CASCADE
-- );

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

CREATE TABLE tbl_event_application (
    event_application_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    proposed_event_id INT NULL, -- Will be populated after approval
    applicant_user_id VARCHAR(200) NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', 'Revision') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id, cycle_number) 
        REFERENCES tbl_renewal_cycle(organization_id, cycle_number),
    FOREIGN KEY (applicant_user_id) REFERENCES tbl_user(user_id),
    FOREIGN KEY (proposed_event_id) REFERENCES tbl_event(event_id)
);

CREATE TABLE tbl_event_application_requirement (
    requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    requirement_name VARCHAR(255) NOT NULL,
    is_applicable_to ENUM('pre-event', 'post-event') DEFAULT 'pre-event',
    file_path VARCHAR(255) NULL,
    created_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES tbl_user(user_id)
);
-- 3. Event Application Approval Process
CREATE TABLE tbl_event_approval_process (
    event_approval_id INT AUTO_INCREMENT PRIMARY KEY,
    event_application_id INT NOT NULL,
    approver_id VARCHAR(200) NOT NULL,
    approval_role_id INT NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    comment TEXT,
    step_number INT NOT NULL,
    approved_at TIMESTAMP NULL,
    FOREIGN KEY (event_application_id) 
        REFERENCES tbl_event_application(event_application_id),
    FOREIGN KEY (approver_id) REFERENCES tbl_user(user_id),
    FOREIGN KEY (approval_role_id) REFERENCES tbl_role(role_id)
);


CREATE TABLE tbl_event_application_submission (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    event_application_id INT,
    requirement_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    submitted_by VARCHAR(200) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_application_id) REFERENCES tbl_event_application(event_application_id),
    FOREIGN KEY (requirement_id) REFERENCES tbl_event_application_requirement(requirement_id),
    FOREIGN KEY (submitted_by) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_event_requirement_submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    event_application_id INT,
    requirement_id INT NOT NULL,
    cycle_number INT NOT NULL,
    organization_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    submitted_by VARCHAR(200) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id),
    FOREIGN KEY (event_application_id) REFERENCES tbl_event_application(event_application_id),
    FOREIGN KEY (requirement_id) REFERENCES tbl_event_application_requirement(requirement_id),
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

CREATE TABLE tbl_event_attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    status ENUM('Pending', 'Registered', 'Evaluated', 'Attended', 'Rejected') NOT NULL,
    time_in DATETIME DEFAULT NULL,
    time_out DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
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
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending', -- use capitalized values everywhere
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
    remarks VARCHAR(255) DEFAULT NULL,
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

CREATE DEFINER='admin'@'%' PROCEDURE ArchiveOrganization(
    IN p_organization_id INT,
    IN p_user_id VARCHAR(200)
)
BEGIN
    -- Update organization status to 'Archived'
    UPDATE tbl_organization
    SET status = 'Archived',
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data
    ) VALUES (
        p_user_id,
        CONCAT('Archived organization ID ', p_organization_id),
        'organization',
        JSON_OBJECT('organization_id', p_organization_id, 'archived_at', NOW())
    );
END $$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE UnarchiveOrganization(
    IN p_organization_id INT,
    IN p_user_id VARCHAR(200)
)
BEGIN
    -- Unarchive organization (set status to 'Approved', or change as needed)
    UPDATE tbl_organization
    SET status = 'Approved',
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND status = 'Archived';

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data
    ) VALUES (
        p_user_id,
        CONCAT('Unarchived organization ID ', p_organization_id),
        'organization',
        JSON_OBJECT('organization_id', p_organization_id, 'unarchived_at', NOW())
    );
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
    UPDATE tbl_application_requirement 
    SET requirement_name = p_requirement_name, file_path = p_file_path
    WHERE requirement_id = p_requirement_id;
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

CREATE DEFINER='admin'@'%' PROCEDURE GetAllPeriodsWithApplications()
BEGIN
    SELECT 
        ap.period_id,
        ap.start_date,
        ap.end_date,
        ap.start_time,
        ap.end_time,
        ap.is_active,
        ap.created_by,
        ap.created_at,
        ap.updated_at,
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'application_id', a.application_id,
                    'organization_id', a.organization_id,
                    'cycle_number', a.cycle_number,
                    'application_type', a.application_type,
                    'applicant_user_id', a.applicant_user_id,
                    'status', a.status,
                    'created_at', a.created_at,
                    'updated_at', a.updated_at,
                    'organization_name', o.name
                )
            )
            FROM tbl_application a
            LEFT JOIN tbl_organization o ON a.organization_id = o.organization_id
            WHERE a.period_id = ap.period_id
        ) AS applications
    FROM tbl_application_period ap
    ORDER BY ap.start_date DESC, ap.period_id DESC;
END $$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetActiveApplicationPeriodSimple()
BEGIN
    SELECT *
    FROM tbl_application_period
    WHERE is_active = 1
    ORDER BY created_at DESC
    LIMIT 1;
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

CREATE DEFINER='admin'@'%' PROCEDURE UpdateApplicationPeriod(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME,
    IN p_period_id INT
)
BEGIN
    UPDATE tbl_application_period
    SET start_date = p_start_date,
        end_date = p_end_date,
        start_time = p_start_time,
        end_time = p_end_time
    WHERE period_id = p_period_id;

END $$
DELIMITER ;

DELIMITER $$

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE TerminateActiveApplicationPeriod(
    IN p_user_id VARCHAR(200)
)
BEGIN
    DECLARE v_affected_rows INT DEFAULT 0;

    -- Terminate all currently active periods
    UPDATE tbl_application_period
    SET is_active = 0
    WHERE is_active = 1;

    SET v_affected_rows = ROW_COUNT();

    -- Log the action if any period was terminated
    IF v_affected_rows > 0 THEN
        INSERT INTO tbl_logs (
            user_id,
            action,
            type,
            meta_data
        ) VALUES (
            p_user_id,
            'Terminated active application period(s)',
            'application_period',
            JSON_OBJECT('terminated_count', v_affected_rows, 'terminated_at', NOW())
        );
    END IF;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE InitiateApprovalProcess(IN p_application_id INT)
BEGIN
    DECLARE v_org_id INT;
    DECLARE v_program_id INT;
    DECLARE v_adviser_id VARCHAR(200);
    DECLARE v_period_id INT;
    DECLARE v_role_id INT;
    DECLARE v_hierarchy_order INT;
    DECLARE v_approver_id VARCHAR(200);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE step_counter INT DEFAULT 0;

    DECLARE role_cursor CURSOR FOR
        SELECT role_id, hierarchy_order
        FROM tbl_role
        WHERE is_approver = TRUE
        AND hierarchy_order IS NOT NULL
        ORDER BY hierarchy_order;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Get application details
    SELECT o.organization_id, o.base_program_id, o.adviser_id, a.period_id
    INTO v_org_id, v_program_id, v_adviser_id, v_period_id
    FROM tbl_application a
    JOIN tbl_organization o ON a.organization_id = o.organization_id
    WHERE a.application_id = p_application_id;

    -- Validate Adviser role
    IF NOT EXISTS (
        SELECT 1 FROM tbl_user 
        WHERE user_id = v_adviser_id 
        AND role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'Adviser')
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization adviser must have Adviser role';
    END IF;

    OPEN role_cursor;

    role_loop: LOOP
        FETCH role_cursor INTO v_role_id, v_hierarchy_order;
        IF done THEN
            LEAVE role_loop;
        END IF;

        SET step_counter = step_counter + 1;

        -- Find approver logic
        IF v_role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'Adviser') THEN
            SET v_approver_id = v_adviser_id;
        ELSEIF v_role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'ProgramChair') THEN
            SELECT u.user_id INTO v_approver_id
            FROM tbl_user u
            WHERE u.role_id = v_role_id
            AND u.program_id = v_program_id
            LIMIT 1;
        ELSE
            SELECT u.user_id INTO v_approver_id
            FROM tbl_user u
            WHERE u.role_id = v_role_id
            LIMIT 1;
        END IF;

        -- Insert approval step with auto-approve first step
        IF v_approver_id IS NOT NULL THEN
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
                v_period_id,
                v_approver_id,
                v_role_id,
                a.application_type,
                CASE 
                    WHEN step_counter = 1 THEN 'Approved'  -- Auto-approve first step
                    ELSE 'Pending'
                END,
                v_hierarchy_order
            FROM tbl_application a
            WHERE a.application_id = p_application_id;
        END IF;
    END LOOP role_loop;

    CLOSE role_cursor;

    -- Validate steps
    IF NOT EXISTS (
        SELECT 1 FROM tbl_approval_process 
        WHERE organization_id = v_org_id
        AND period_id = v_period_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No valid approval steps created';
    END IF;

    -- Link approvals to application
    INSERT INTO tbl_application_approval (application_id, approval_id)
    SELECT p_application_id, approval_id
    FROM tbl_approval_process
    WHERE organization_id = v_org_id
    AND period_id = v_period_id;

    -- Update application status remains as 'Pending'
    UPDATE tbl_application 
    SET status = 'Pending'
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
    DECLARE v_name_exists TINYINT(1) DEFAULT 0;
    
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

    -- Check organization name uniqueness
    SET v_org_name = JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_name'));
    SELECT EXISTS(
        SELECT 1 
        FROM tbl_organization 
        WHERE name = v_org_name
    ) INTO v_name_exists;

    IF v_name_exists THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization name already exists. Please choose a different name.';
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
        v_org_name,
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_description')),
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.organization_logo')),
        v_program_id,
        'Pending',
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.fee_duration')),
        CASE
            WHEN JSON_EXTRACT(p_organization, '$.fee_amount') IS NULL 
                 OR JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.fee_amount')) = 'null'
                THEN NULL
            ELSE CAST(JSON_EXTRACT(p_organization, '$.fee_amount') AS DECIMAL(10,2))
        END,
        FALSE,
        FALSE,
        JSON_UNQUOTE(JSON_EXTRACT(p_organization, '$.category'))
    );

    SET v_organization_id = LAST_INSERT_ID();
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

    -- Create renewal cycle
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
        e.is_open_to,
        e.venue_type,
        e.venue,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
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
        e.is_open_to,
        e.venue_type,
        e.venue,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE e.event_id = p_event_id;
END $$

DELIMITER ;

    -- Get attendees per event
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventAttendeesWithDetails(
    IN p_event_id INT
)
BEGIN
    SELECT
        ea.attendance_id,
        ea.event_id,
        ea.user_id,
        CONCAT(u.f_name, ' ', u.l_name) AS full_name,
        u.email,
        u.profile_picture,
        ea.status AS attendance_status,
        te.remarks,
        ea.time_in,
        ea.time_out,
        ea.created_at AS registration_date,
        t.transaction_id,
        t.amount,
        t.transaction_type,
        t.status AS transaction_status,
        t.proof_image,
        t.created_at AS transaction_created_at
    FROM tbl_event_attendance ea
    LEFT JOIN tbl_user u ON ea.user_id = u.user_id
    LEFT JOIN tbl_transaction_event te ON ea.event_id = te.event_id AND ea.user_id = (SELECT user_id FROM tbl_transaction WHERE transaction_id = te.transaction_id LIMIT 1)
    LEFT JOIN tbl_transaction t ON te.transaction_id = t.transaction_id
    WHERE ea.event_id = p_event_id;
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
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.capacity,
        e.certificate,
        e.fee,
        e.is_open_to,
        e.venue_type,
        e.venue,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE e.status = p_status;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetSpecificApplication(
    IN p_user_id VARCHAR(200),
    IN p_organization_name VARCHAR(100)
    )
BEGIN
    DECLARE v_organization_id INT;
    DECLARE v_application_id INT;
    DECLARE v_applicant_user_id VARCHAR(200);

    -- Security First: Validate User Access
    SELECT o.organization_id, a.application_id, a.applicant_user_id
    INTO v_organization_id, v_application_id, v_applicant_user_id
    FROM tbl_organization o
    JOIN tbl_application a ON o.organization_id = a.organization_id
    WHERE o.name = p_organization_name
    LIMIT 1;

    -- Error Handling: No Access or Not Found
    IF v_organization_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization not found or access denied';
    END IF;

    -- Main Query: Single JSON Output
    SELECT JSON_OBJECT(
        'metadata', JSON_OBJECT(
            'retrieved_at', NOW(),
            'requested_by', p_user_id
        ),
        'organization', (
            SELECT JSON_OBJECT(
                'id', o.organization_id,
                'name', o.name,
                'logo_url', o.logo,
                'status', o.status,
                'category', o.category,
                'membership_info', JSON_OBJECT(
                    'fee_type', o.membership_fee_type,
                    'fee_amount', o.membership_fee_amount,
                    'recruiting', o.is_recruiting,
                    'open_courses', o.is_open_to_all_courses
                ),
                'program', JSON_OBJECT(
                    'id', p.program_id,
                    'name', p.name,
                    'description', p.description
                )
            )
            FROM tbl_organization o
            LEFT JOIN tbl_program p ON o.base_program_id = p.program_id
            WHERE o.organization_id = v_organization_id
        ),
        'application', (
            SELECT JSON_OBJECT(
                'id', a.application_id,
                'current_status', a.status,
                'submission_date', a.created_at,
                'cycle_number', a.cycle_number,
                'submitted_by', CONCAT(u.f_name, ' ', u.l_name),
                'requirements', COALESCE(
                    (SELECT JSON_ARRAYAGG(
                        JSON_OBJECT(
                            'requirement_id', rs.requirement_id,
                            'name', ar.requirement_name,
                            'submitted_file', rs.file_path,
                            'submitted_at', rs.submitted_at
                        )
                    )
                    FROM tbl_organization_requirement_submission rs
                    JOIN tbl_application_requirement ar 
                        ON rs.requirement_id = ar.requirement_id
                    WHERE rs.application_id = a.application_id),
                    JSON_ARRAY()
                )
            )
            FROM tbl_application a
            LEFT JOIN tbl_user u ON a.applicant_user_id = u.user_id
            WHERE a.application_id = v_application_id
        ),
        'leadership', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'member_id', om.member_id,
                    'user_id', om.user_id,
                    'name', CONCAT(u.f_name, ' ', u.l_name),
                    'email', u.email,
                    'role', er.role_title,
                    'rank', erk.rank_level,
                    'permissions', (
                        SELECT JSON_ARRAYAGG(p.permission_name)
                        FROM tbl_rank_permission rp
                        JOIN tbl_permission p 
                            ON rp.permission_id = p.permission_id
                        WHERE rp.rank_id = erk.rank_id
                    )
                )
            )
            FROM tbl_organization_members om
            JOIN tbl_executive_role er 
                ON om.executive_role_id = er.executive_role_id
            JOIN tbl_executive_rank erk 
                ON er.rank_id = erk.rank_id
            JOIN tbl_user u 
                ON om.user_id = u.user_id
            WHERE om.organization_id = v_organization_id
        ),
        'approval_timeline', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'approval_id', ap.approval_id,
                    'step_number', ap.step,
                    'required_role', r.role_name,
                    'status', ap.status,
                    'processed_by', COALESCE(u.email, 'pending'),
                    'processed_by_name', CONCAT(u.f_name, ' ', u.l_name),
                    'processed_by_user_id', u.user_id,
                    'comments', ap.comment,
                    'last_update', ap.timestamp
                )
            )
            FROM tbl_approval_process ap
            JOIN tbl_role r 
                ON ap.approval_role_id = r.role_id
            LEFT JOIN tbl_user u 
                ON ap.approver_id = u.user_id
            WHERE ap.organization_id = v_organization_id
            ORDER BY ap.step
        )
    ) AS result;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ApproveApplication(
    IN p_approval_id INT,
    IN p_comment TEXT,
    IN p_organization_id INT,
    IN p_application_id INT
)
BEGIN
    DECLARE v_step INT;  -- Moved declaration to top of BEGIN block

    -- Update approval status
    UPDATE tbl_approval_process
    SET 
        comment = p_comment,
        status = 'Approved',
        `timestamp` = CURRENT_TIMESTAMP
    WHERE approval_id = p_approval_id;

    -- Get current step value
    SELECT `step` INTO v_step
    FROM tbl_approval_process
    WHERE approval_id = p_approval_id;

    -- Check if final approval step
    IF v_step = 5 THEN
        -- Update application status
        UPDATE tbl_application
        SET status = 'approved',
            updated_at = CURRENT_TIMESTAMP
        WHERE application_id = p_application_id;

        -- Update organization status
        UPDATE tbl_organization
        SET status = 'Approved'
        WHERE organization_id = p_organization_id;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE RejectApplication(
    IN p_application_id INT,
    IN p_approval_id INT,
    IN p_organization_id INT,
    IN p_comment TEXT
)
BEGIN

    START TRANSACTION;

    -- Update approval process
    UPDATE tbl_approval_process
    SET status = 'Rejected',
        comment = p_comment,
        timestamp = CURRENT_TIMESTAMP
    WHERE approval_id = p_approval_id;

    -- Update application status
    UPDATE tbl_application
    SET status = 'rejected',
        updated_at = CURRENT_TIMESTAMP
    WHERE application_id = p_application_id;

    -- Update organization status
    UPDATE tbl_organization
    SET status = 'Rejected'
    WHERE organization_id = p_organization_id;

    COMMIT;
END$$
DELIMITER ;

-- Get past events
DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetPastEvents()
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
        e.is_open_to,
        e.venue_type,
        e.venue,
        e.organization_id,
        o.name AS organization_name,
        e.status,
        e.type,
        e.user_id,
        e.created_at
    FROM tbl_event e
    JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE e.status = 'Approved'
      AND (
        (e.end_date IS NOT NULL AND e.end_date < CURDATE()) OR
        (e.end_date IS NULL AND e.start_date < CURDATE())
      )
    ORDER BY e.end_date DESC, e.start_date DESC;
END $$
DELIMITER ;

DELIMITER $$

-- Procedure to approve attendance and transaction
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE ApprovePaidEventRegistration(
    IN p_event_id INT,
    IN p_user_id VARCHAR(200),
    IN p_approver_id VARCHAR(200),
    IN p_remarks VARCHAR(255) -- optional, can be NULL
)
BEGIN
    DECLARE v_attendance_id INT;
    DECLARE v_transaction_id INT;
    DECLARE v_final_remarks VARCHAR(255);

    -- Set remarks to 'No Remarks' if NULL or empty
    IF p_remarks IS NULL OR LENGTH(TRIM(p_remarks)) = 0 THEN
        SET v_final_remarks = 'No Remarks';
    ELSE
        SET v_final_remarks = p_remarks;
    END IF;

    -- Find the attendance record
    SELECT attendance_id INTO v_attendance_id
    FROM tbl_event_attendance
    WHERE event_id = p_event_id AND user_id = p_user_id
    LIMIT 1;

    IF v_attendance_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No registration found for this event and user';
    END IF;

    -- Get transaction ID if exists
    SELECT te.transaction_id INTO v_transaction_id
    FROM tbl_transaction_event te
    JOIN tbl_transaction t ON te.transaction_id = t.transaction_id
    WHERE te.event_id = p_event_id AND t.user_id = p_user_id
    LIMIT 1;

    -- Update attendance status
    UPDATE tbl_event_attendance
    SET status = 'Registered'
    WHERE attendance_id = v_attendance_id;

    -- Update transaction status and remarks if exists
    IF v_transaction_id IS NOT NULL THEN
        UPDATE tbl_transaction
        SET status = 'Completed'
        WHERE transaction_id = v_transaction_id;

        UPDATE tbl_transaction_event
        SET remarks = CONCAT('Approved: ', v_final_remarks)
        WHERE transaction_id = v_transaction_id;
    END IF;

    -- Log the approval
    INSERT INTO tbl_logs (user_id, action, redirect_url, type)
    VALUES (
        p_approver_id, 
        CONCAT('Approved registration for event ', p_event_id), 
        CONCAT('/event-attendance/', p_event_id), 
        'Attendance Approval'
    );

    SELECT 'Attendance approved successfully' AS message;
END $$

DELIMITER ;

     -- Reject Registration
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE RejectPaidEventRegistration(
    IN p_event_id INT,
    IN p_user_id VARCHAR(200),
    IN p_approver_id VARCHAR(200),
    IN p_reason VARCHAR(255)
)
BEGIN
    DECLARE v_attendance_id INT;
    DECLARE v_transaction_id INT;

    -- Find the attendance record
    SELECT attendance_id INTO v_attendance_id
    FROM tbl_event_attendance
    WHERE event_id = p_event_id AND user_id = p_user_id AND deleted_at IS NULL
    LIMIT 1;

    IF v_attendance_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No registration found for this event and user';
    END IF;

    -- Get transaction ID if exists
    SELECT te.transaction_id INTO v_transaction_id
    FROM tbl_transaction_event te
    JOIN tbl_transaction t ON te.transaction_id = t.transaction_id
    WHERE te.event_id = p_event_id AND t.user_id = p_user_id
    LIMIT 1;

    -- Soft-delete attendance using deleted_at
    UPDATE tbl_event_attendance
    SET deleted_at = NOW(), status = 'Rejected'
    WHERE attendance_id = v_attendance_id;

    -- Update transaction status and remarks if exists
    IF v_transaction_id IS NOT NULL THEN
        UPDATE tbl_transaction
        SET status = 'Failed'
        WHERE transaction_id = v_transaction_id;

        UPDATE tbl_transaction_event
        SET remarks = CONCAT('Rejected: ', p_reason)
        WHERE transaction_id = v_transaction_id;
    END IF;

    -- Log the rejection
    INSERT INTO tbl_logs (user_id, action, meta_data, type)
    VALUES (
        p_approver_id, 
        CONCAT('Rejected registration for event ', p_event_id), 
        JSON_OBJECT('user_id', p_user_id, 'reason', p_reason),
        'Attendance Rejection'
    );

    SELECT 'Attendance rejected and soft-deleted successfully' AS message;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationApplications()
BEGIN

    SELECT 
        org.organization_id,
        org.name AS organization_name,
        org.logo AS organization_logo,
        org.status AS organization_status,
        org.category,
        org.base_program_id,
        p.name AS program_name,
        org.membership_fee_type,
        org.membership_fee_amount,
        org.is_recruiting,
        org.is_open_to_all_courses,
        org.created_at AS organization_created,
        app.application_id,
        app.cycle_number,
        app.application_type,
        app.period_id,
        app.applicant_user_id,
        app.status AS application_status,
        app.created_at AS application_created,
        app.updated_at AS application_updated
    FROM tbl_organization org
    INNER JOIN tbl_application app 
        ON org.organization_id = app.organization_id
    LEFT JOIN tbl_program p
        ON org.base_program_id = p.program_id
    WHERE app.status = 'Pending'
    ORDER BY org.created_at DESC, app.created_at DESC;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventRequirements()
BEGIN
    SELECT * FROM tbl_event_application_requirement;
END $$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE SaveEventRequirements(
    IN p_user_id VARCHAR(200),
    IN p_requirements JSON
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE req_count INT;
    DECLARE v_req_id INT;
    DECLARE v_req_name VARCHAR(255);
    DECLARE v_req_type ENUM('pre-event', 'post-event');
    DECLARE v_file_path VARCHAR(255);

    DECLARE done INT DEFAULT FALSE;
    DECLARE del_req_id INT;
    DECLARE del_req_name VARCHAR(255);
    DECLARE del_cursor CURSOR FOR SELECT requirement_id FROM tmp_existing_ids;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 1. Collect all current requirement_ids
    DROP TEMPORARY TABLE IF EXISTS tmp_existing_ids;
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_existing_ids (requirement_id INT PRIMARY KEY);
    INSERT INTO tmp_existing_ids (requirement_id)
        SELECT requirement_id FROM tbl_event_application_requirement;

    SET req_count = JSON_LENGTH(p_requirements);

    -- 2. Add or update requirements
    WHILE i < req_count DO
        SET v_req_id = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].requirement_id')));
        SET v_req_name = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].requirement_name')));
        SET v_req_type = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].is_applicable_to')));
        SET v_file_path = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].file_path')));

        IF v_req_id IS NULL OR v_req_id = '' OR v_req_id = 'null' THEN
            -- Add new requirement
            INSERT INTO tbl_event_application_requirement (
                requirement_name, is_applicable_to, file_path, created_by
            ) VALUES (
                v_req_name, v_req_type, v_file_path, p_user_id
            );

            -- Log add
            INSERT INTO tbl_logs (user_id, action, type, meta_data)
            VALUES (
                p_user_id,
                CONCAT('Added event requirement: ', v_req_name),
                'event_requirement',
                JSON_OBJECT('requirement_name', v_req_name, 'is_applicable_to', v_req_type)
            );
        ELSE
            -- Update existing requirement
            UPDATE tbl_event_application_requirement
            SET requirement_name = v_req_name,
                is_applicable_to = v_req_type,
                file_path = v_file_path,
                updated_at = CURRENT_TIMESTAMP
            WHERE requirement_id = v_req_id;

            -- Log update
            INSERT INTO tbl_logs (user_id, action, type, meta_data)
            VALUES (
                p_user_id,
                CONCAT('Updated event requirement: ', v_req_name),
                'event_requirement',
                JSON_OBJECT('requirement_id', v_req_id, 'requirement_name', v_req_name, 'is_applicable_to', v_req_type)
            );
        END IF;

        -- Remove from deletion candidates
        IF v_req_id IS NOT NULL AND v_req_id != '' THEN
            DELETE FROM tmp_existing_ids WHERE requirement_id = v_req_id;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- 3. Delete requirements not in the new list and log deletions
    OPEN del_cursor;
    del_loop: LOOP
        FETCH del_cursor INTO del_req_id;
        IF done THEN
            LEAVE del_loop;
        END IF;

        -- Get name for logging
        SELECT requirement_name INTO del_req_name FROM tbl_event_application_requirement WHERE requirement_id = del_req_id;

        DELETE FROM tbl_event_application_requirement WHERE requirement_id = del_req_id;

        -- Log deletion
        INSERT INTO tbl_logs (user_id, action, type, meta_data)
        VALUES (
            p_user_id,
            CONCAT('Deleted event requirement: ', del_req_name),
            'event_requirement',
            JSON_OBJECT('requirement_id', del_req_id, 'requirement_name', del_req_name)
        );
    END LOOP;
    CLOSE del_cursor;

    DROP TEMPORARY TABLE IF EXISTS tmp_existing_ids;
END $$

DELIMITER ;

-- Procedure to get event statistics
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventStatistics(IN p_event_id INT)
BEGIN
    -- Number of attendees (status = 'Attended')
    SELECT COUNT(*) INTO @attendees_count
    FROM tbl_event_attendance
    WHERE event_id = p_event_id AND (status = 'Attended' OR status = 'Evaluated');
    
    -- Number of feedbacks (status = 'Evaluated' or has evaluation)
    SELECT COUNT(DISTINCT ea.user_id) INTO @feedback_count
    FROM tbl_event_attendance ea
    LEFT JOIN tbl_evaluation e ON ea.user_id = e.user_id AND ea.event_id = e.event_id
    WHERE ea.event_id = p_event_id 
    AND (ea.status = 'Evaluated' OR e.evaluation_id IS NOT NULL);
    
    -- Average rating (average of all likert_4 responses)
    SELECT AVG(CAST(response_value AS DECIMAL)) INTO @avg_rating
    FROM tbl_evaluation_response er
    JOIN tbl_evaluation e ON er.evaluation_id = e.evaluation_id
    JOIN tbl_evaluation_question eq ON er.question_id = eq.question_id
    WHERE e.event_id = p_event_id AND eq.question_type = 'likert_4';
    
    -- Average feedback time in seconds
    SELECT AVG(duration_seconds) INTO @avg_feedback_time
    FROM tbl_evaluation
    WHERE event_id = p_event_id;
    
    -- Return all statistics
    SELECT 
        @attendees_count AS attendeesCount,
        @feedback_count AS feedbackCount,
        ROUND(COALESCE(@avg_rating, 0), 2) AS averageRating,
        CONCAT(FLOOR(COALESCE(@avg_feedback_time, 0) / 60), 'm ', 
               MOD(COALESCE(@avg_feedback_time, 0), 60), 's') AS avgFeedbackTime;
END $$

DELIMITER ;

-- Procedure to get event statistics for React component
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventStatsForComponent(IN p_event_id INT)
BEGIN
    DECLARE v_attendees_count INT;
    DECLARE v_feedback_count INT;
    DECLARE v_avg_rating DECIMAL(10,2);
    DECLARE v_avg_feedback_time VARCHAR(20);
    
    -- Get statistics
    CALL GetEventStatistics(p_event_id);
    
    -- Format the results for React component
    SELECT 
        attendeesCount,
        feedbackCount,
        averageRating,
        avgFeedbackTime
    FROM (
        SELECT 
            @attendees_count AS attendeesCount,
            @feedback_count AS feedbackCount,
            ROUND(COALESCE(@avg_rating, 0), 2) AS averageRating,
            CASE 
                WHEN @avg_feedback_time IS NULL THEN '0s'
                WHEN @avg_feedback_time < 60 THEN CONCAT(@avg_feedback_time, 's')
                ELSE CONCAT(FLOOR(@avg_feedback_time / 60), 'm ', MOD(@avg_feedback_time, 60), 's')
            END AS avgFeedbackTime
    ) AS stats;
END $$

DELIMITER ;

    -- Get all evaluation questions
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetAllEvaluationQuestions()
BEGIN
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'group_id', g.group_id,
            'group_title', g.group_title,
            'group_description', g.group_description,
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
    WHERE g.is_active = TRUE;
END $$

DELIMITER ;

    -- Get all evaluation responses grouped by question group
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventEvaluationResponsesByGroup(
    IN p_event_id INT
)
BEGIN
    SELECT 
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'group_title', qg.group_title,
                'group_description', qg.group_description,
                'questions', (
                    SELECT JSON_ARRAYAGG(
                        JSON_OBJECT(
                            'question_id', q.question_id,
                            'question_text', q.question_text,
                            'question_type', q.question_type,
                            'responses', (
                                SELECT JSON_ARRAYAGG(
                                    JSON_OBJECT(
                                        'user_id', u.user_id,
                                        'attendee_name', CONCAT(u.f_name, ' ', u.l_name),
                                        'response_value', r.response_value,
                                        'response_time', r.created_at
                                    )
                                )
                                FROM tbl_evaluation_response r
                                JOIN tbl_evaluation e ON r.evaluation_id = e.evaluation_id
                                JOIN tbl_user u ON e.user_id = u.user_id
                                WHERE r.question_id = q.question_id
                                AND e.event_id = p_event_id
                            )
                        )
                    )
                    FROM tbl_evaluation_question q
                    WHERE q.group_id = qg.group_id
                )
            )
        ) AS evaluation_responses
    FROM 
        tbl_evaluation_question_group qg
    WHERE 
        EXISTS (
            SELECT 1
            FROM tbl_event_evaluation_config ec
            WHERE ec.event_id = p_event_id
            AND ec.group_id = qg.group_id
        )
    ORDER BY 
        qg.group_id;
END $$

DELIMITER ;

    -- Get logs
DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetLogs(
    IN p_user_id VARCHAR(200),
    IN p_type VARCHAR(100),
    IN p_start_date DATETIME,
    IN p_end_date DATETIME
)
BEGIN
    SELECT 
        l.log_id,
        l.user_id,
        CONCAT(u.f_name, ' ', u.l_name) AS full_name,
        u.profile_picture,
        l.timestamp,
        l.action,
        l.redirect_url,
        l.file_path,
        l.meta_data,
        l.type
    FROM tbl_logs l
    LEFT JOIN tbl_user u ON l.user_id = u.user_id
    WHERE
        (p_user_id IS NULL OR l.user_id = p_user_id)
        AND (p_type IS NULL OR l.type = p_type)
        AND (p_start_date IS NULL OR l.timestamp >= p_start_date)
        AND (p_end_date IS NULL OR l.timestamp <= p_end_date)
    ORDER BY l.timestamp DESC;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CheckOrganizationName(
    IN p_organization_name VARCHAR(100)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    -- Check if organization name exists
    SELECT COUNT(*) INTO v_exists
    FROM tbl_organization
    WHERE name = p_organization_name;

    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization name already exists. Please choose a different name.';
    END IF;
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CheckOrganizationEmails(
    IN p_emails JSON
)
BEGIN
    -- Returns { unavailable: [email1, email2, ...] }
    -- unavailable if: not student role OR is executive in any org

    DECLARE unavailable_emails JSON DEFAULT JSON_ARRAY();

    -- 1. Not student role
    SELECT JSON_ARRAYAGG(u.email)
      INTO @not_students
      FROM tbl_user u
      JOIN tbl_role r ON u.role_id = r.role_id
     WHERE JSON_CONTAINS(p_emails, CAST(u.email AS JSON))
       AND LOWER(r.role_name) != 'student';

    -- 2. Is executive in any org
    SELECT JSON_ARRAYAGG(u.email)
      INTO @executives
      FROM tbl_user u
      JOIN tbl_organization_members om ON u.user_id = om.user_id
     WHERE JSON_CONTAINS(p_emails, CAST(u.email AS JSON))
       AND om.member_type = 'Executive';

    -- Merge both arrays, remove nulls
    SET unavailable_emails = JSON_MERGE_PRESERVE(
        COALESCE(@not_students, JSON_ARRAY()),
        COALESCE(@executives, JSON_ARRAY())
    );

    -- Remove duplicates
    SET unavailable_emails = (
        SELECT JSON_ARRAYAGG(email) FROM (
            SELECT DISTINCT jt.email
            FROM JSON_TABLE(
                unavailable_emails, '$[*]' COLUMNS (email VARCHAR(255) PATH '$')
            ) jt
        ) uniq
    );

    SELECT JSON_OBJECT('unavailable', COALESCE(unavailable_emails, JSON_ARRAY())) AS result;
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
    AND 
      end_date < CURDATE();
END $$
DELIMITER ;

-- SAMPLE DATAS
INSERT INTO tbl_role(role_name, is_approver, hierarchy_order)
VALUES("Student",0,null), 
("Adviser",1,1),
("Program Chair",1,2),
("SDAO",1,5),
("Dean",1,3),
("Academic Director",1,4);

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
("WEB_ACCESS"),
("MANAGE_REGISTRATION");

INSERT INTO tbl_role_permission (role_id, permission_id) 
VALUES
(4,1),
(4,2),
(4,3),
(4,4),
(4,8),
(4,9),
(4,10),
(4,15),
(4,22),
(4,23),
(2,6),
(2,9),
(2,23),
(4,24);


INSERT INTO tbl_program (name, description) VALUES 
("Bachelor of Science in Information Technology", "BSIT"),
("Bachelor of Science in Computer Science", "BSCS");

INSERT INTO tbl_user (user_id, f_name, l_name, email, program_id, role_id) VALUES
("900f929ec408cb4", "Benson","Javier","benson09.javier@outlook.com", 1 , 1),
("5fb95ed0a0d20daf", "Geraldine","Aris","arisgeraldine@outlook.com", null, 6),
("6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0", "Benson","Javier","javierbb@students.nu-dasma.edu.ph",null,4),
("cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k", "Carl Roehl", "Falcon", "falconcs@students.nu-dasma.edu.ph", 1, 3),
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Samantha Joy", "Madrunio", "madruniosm@students.nu-dasma.edu.ph", 1, 2),
("_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU", "Geraldine", "Aris", "arisgc@students.nu-dasma.edu.ph",null, 4);


INSERT INTO tbl_executive_rank (rank_level, default_title, description) VALUES
(1, 'President', 'Highest authority with full permissions'),
(2, 'Vice President', 'Second-in-command'),
(3, 'Secretary', 'Administrative lead'),
(4, 'Treasurer', 'Financial manager'),
(5, 'Officer', 'General executive member');

INSERT INTO tbl_organization (adviser_id, name, description, base_program_id, status, membership_fee_type, membership_fee_amount, is_recruiting, is_open_to_all_courses) VALUES
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Computer Society", "This is the computer society", 1, "Approved", "Whole Academic Year", 500, 0, 0),
("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Isite","This is Isite", 2, "Approved", "Whole Academic Year", 500,0,0);

INSERT INTO tbl_event_application_requirement (
    requirement_name,
    is_applicable_to,
    file_path,
    created_by,
    created_at,
    updated_at
) VALUES
('Event Proposal Form', 'pre-event', 'requirement-1747711120933-Letter-of-Intent.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:18:40', '2025-05-20 11:18:40'),
('Program Flow', 'pre-event', 'requirement-1747711141257-ACO-SA-F-002Student-Org-Application-Form.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:01', '2025-05-20 11:19:01'),
('Budget Proposal', 'pre-event', 'requirement-1747711157238-Constitution-and-ByLaws.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:17', '2025-05-20 11:19:17'),
('Attendance Sheet', 'post-event', 'requirement-1747711169050-List-of-Officers-and-Founders.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:29', '2025-05-20 11:19:29'),
('Event Photos', 'post-event', 'requirement-1747711179629-Letter-from-the-College-Dean.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:39', '2025-05-20 11:19:39'),
('Narrative Report', 'post-event', 'requirement-1747711196157-List-of-Members.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:19:56', '2025-05-20 11:19:56'),
('Financial Report', 'post-event', 'requirement-1747711230696-Latest-Certificate-of-Grades-of-Officers.pdf', '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-05-20 11:20:30', '2025-05-20 11:20:30');

INSERT INTO tbl_event (
  event_id,
  organization_id,
  user_id,
  title,
  description,
  venue_type,
  venue,
  start_date,
  end_date,
  start_time,
  end_time,
  status,
  type,
  is_open_to,
  fee,
  capacity,
  created_at,
  certificate
) VALUES
(1001, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Innovation Pitch Fest', 'A competition for pitching new ideas', 'Face to face', 'NU Hall A', '2025-06-10', '2025-06-10', '09:00:00', '15:00:00', 'Approved', 'Paid', 'Open to all', 50, 100, '2025-05-01 08:00:00', 'Participation Certificate'),

(1002, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Groove Jam 2025', 'Annual inter-school dance battle', 'Face to face', 'Open Grounds', '2025-07-20', '2025-07-20', '13:00:00', '19:00:00', 'Approved', 'Free', 'Open to all', 0, 300, '2025-05-05 10:30:00', 'Winner + Participation'),

(1003, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Hack-It-Out', '24-hour Hackathon for IT majors', 'Face to face', 'Tech Lab 101', '2025-08-05', '2025-08-05', '08:00:00', '08:00:00', 'Pending', 'Paid', 'Members only', 200, 60, '2025-05-12 15:45:00', 'Certificate + Swag'),

(1004, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Earth Hour Rally', 'Tree planting and cleanup event', 'Face to face', 'Community Park', '2025-06-15', '2025-06-15', '06:30:00', '10:30:00', 'Approved', 'Free', 'Open to all', 0, 150, '2025-05-15 09:00:00', 'Eco Warrior Badge'),

(1005, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'E-Sports Showdown', 'Inter-university e-sports competition', 'Face to face', 'Auditorium', '2025-07-01', '2025-07-01', '10:00:00', '18:00:00', 'Rejected', 'Paid', 'Open to all', 100, 500, '2025-05-10 13:15:00', 'Winner Certificate'),

(2001, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Tech Expo', 'Annual technology exposition', 'Face to face', 'NU Convention Center', '2023-03-10', '2023-03-10', '08:00:00', '17:00:00', 'Approved', 'Free', 'Open to all', 0, 500, '2023-02-01 09:00:00', 'Certificate of Participation'),

(2002, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Coding Bootcamp', 'Intensive coding bootcamp for beginners', 'Face to face', 'Lab 202', '2023-04-15', '2023-04-17', '09:00:00', '16:00:00', 'Approved', 'Paid', 'Members only', 100, 50, '2023-03-10 10:00:00', 'Certificate of Completion'),

(2003, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Summer Seminar', 'Seminar on emerging technologies', 'Online', 'Zoom', '2023-05-05', '2023-05-05', '10:00:00', '12:00:00', 'Approved', 'Free', 'NU Students only', 0, 200, '2023-04-20 11:00:00', 'E-Certificate');

-- -- Then insert attendance records
-- INSERT INTO tbl_event_attendance (event_id, user_id, status, time_in, time_out) VALUES
-- -- For Innovation Pitch Fest (event_id 1001)
-- (1001, '900f929ec408cb4', 'Attended', '2025-06-10 08:55:23', '2025-06-10 15:05:45'),
-- (1001, '5fb95ed0a0d20daf', 'Evaluated', '2025-06-10 09:10:12', '2025-06-10 15:00:30'),
-- (1001, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Pending', '2025-06-10 09:30:00', NULL),

-- -- For Groove Jam 2025 (event_id 1002)
-- (1002, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Registered', NULL, NULL),
-- (1002, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Pending', NULL, NULL),

-- -- For Hack-It-Out (event_id 1003)
-- (1003, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 'Pending', NULL, NULL),
-- (1003, '900f929ec408cb4', 'Registered', NULL, NULL),


-- -- For Earth Hour Rally (event_id 1004)
-- (1004, '5fb95ed0a0d20daf', 'Attended', '2025-06-15 06:25:00', '2025-06-15 10:35:00'),
-- (1004, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Attended', '2025-06-15 06:40:00', '2025-06-15 10:20:00'),
-- (1004, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Evaluated', '2025-06-15 07:00:00', NULL),

-- INSERT INTO tbl_event_attendance (
--   event_id, user_id, status, created_at
-- ) VALUES (
--   1001, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 
--   'Rejected', NOW()
-- );

-- -- For E-Sports Showdown (event_id 1005)
-- (1005, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Registered', NULL, NULL),
-- (1005, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 'Pending', NULL, NULL),

-- -- For 2023 Tech Expo (event_id 2001)
-- (2001, '900f929ec408cb4', 'Attended', '2023-03-10 07:45:00', '2023-03-10 17:15:00'),
-- (2001, '5fb95ed0a0d20daf', 'Attended', '2023-03-10 08:10:00', '2023-03-10 16:50:00'),

-- -- For 2023 Coding Bootcamp (event_id 2002)
-- (2002, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Attended', '2023-04-15 08:30:00', '2023-04-17 16:00:00'),
-- (2002, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Evaluated', '2023-04-15 09:00:00', NULL),

-- -- For 2023 Summer Seminar (event_id 2003)
-- (2003, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Registered', NULL, NULL),
-- (2003, '900f929ec408cb4', 'Attended', '2023-05-05 09:45:00', '2023-05-05 12:15:00');


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

-- INSERT INTO tbl_application_period(start_date, end_date, start_time, end_time, is_active, created_by) 
-- VALUES(
-- "2025-05-24",
-- "2025-06-20",
-- "15:24:00",
-- "10:00:00",
-- 1,
-- "6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0"
-- );

-- Insert evaluation question groups
INSERT INTO tbl_evaluation_question_group (group_title, group_description, is_active)
VALUES 
('Activity: Meeting/Seminar/Conference/Workshop/Quiz Bee/Competition/Sport fest, etc.', 'Question about activities', TRUE),
('About the Speaker/Resource person', 'Feedback about event speakers/presenters', TRUE),
('Meals', 'Feedback about meals', TRUE),
('Handouts', 'Feedback about handouts', TRUE),
('Transportation', 'Feedback about transportation', TRUE),
('Comments and Suggestions', 'Feedback about the whole event', TRUE);

-- Insert evaluation questions
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

INSERT INTO tbl_event_attendance (event_id, user_id, status, time_in, time_out) VALUES
-- For Innovation Pitch Fest (event_id 1001)
(1001, '900f929ec408cb4', 'Attended', '2025-06-10 08:55:23', '2025-06-10 15:05:45'),
(1001, '5fb95ed0a0d20daf', 'Evaluated', '2025-06-10 09:10:12', '2025-06-10 15:00:30'),
(1001, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Pending', '2025-06-10 09:30:00', NULL),

-- For Groove Jam 2025 (event_id 1002)
(1002, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Registered', NULL, NULL),
(1002, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Pending', NULL, NULL),

-- For Hack-It-Out (event_id 1003)
(1003, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 'Pending', NULL, NULL),
(1003, '900f929ec408cb4', 'Registered', NULL, NULL),

-- For Earth Hour Rally (event_id 1004)
(1004, '5fb95ed0a0d20daf', 'Attended', '2025-06-15 06:25:00', '2025-06-15 10:35:00'),
(1004, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Attended', '2025-06-15 06:40:00', '2025-06-15 10:20:00'),
(1004, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Evaluated', '2025-06-15 07:00:00', NULL),

-- For E-Sports Showdown (event_id 1005)
(1005, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Registered', NULL, NULL),
(1005, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 'Pending', NULL, NULL),

-- For 2023 Tech Expo (event_id 2001)
(2001, '900f929ec408cb4', 'Attended', '2023-03-10 07:45:00', '2023-03-10 17:15:00'),
(2001, '5fb95ed0a0d20daf', 'Attended', '2023-03-10 08:10:00', '2023-03-10 16:50:00'),

-- For 2023 Coding Bootcamp (event_id 2002)
(2002, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 'Attended', '2023-04-15 08:30:00', '2023-04-17 16:00:00'),
(2002, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Evaluated', '2023-04-15 09:00:00', NULL),

-- For 2023 Summer Seminar (event_id 2003)
(2003, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 'Registered', NULL, NULL),
(2003, '900f929ec408cb4', 'Attended', '2023-05-05 09:45:00', '2023-05-05 12:15:00');

-- First, ensure the event-group mappings exist in tbl_event_evaluation_config
INSERT INTO tbl_event_evaluation_config (event_id, group_id) VALUES
-- For Innovation Pitch Fest (1001)
(1001, 1), (1001, 2), (1001, 3), (1001, 4), (1001, 5), (1001, 6),
-- For Earth Hour Rally (1004)
(1004, 1), (1004, 3), (1004, 6),
-- For 2023 Tech Expo (2001)
(2001, 1), (2001, 2), (2001, 4), (2001, 6);

-- Insert evaluations for event 1001 (Innovation Pitch Fest)
INSERT INTO tbl_evaluation (event_id, user_id, submitted_at, duration_seconds) VALUES
(1001, '900f929ec408cb4', '2025-06-10 15:10:00', 420),
(1001, '5fb95ed0a0d20daf', '2025-06-10 15:05:00', 380);

-- Responses for Benson Javier (user_id: 900f929ec408cb4) for event 1001
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 1, '4'), (1, 2, '4'), (1, 3, '4'), (1, 4, '4'), (1, 5, '4'), 
(1, 6, '3'), (1, 7, '4'), (1, 8, '4'), (1, 9, '4'), (1, 10, '4'), (1, 11, '4');

-- Group 2: Speaker questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 12, '4'), (1, 13, '4'), (1, 14, '4');

-- Group 3: Meals questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 15, '4'), (1, 16, '4');

-- Group 4: Handouts questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 17, '4'), (1, 18, '4');

-- Group 5: Transportation questions (marked as not applicable)
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 19, '3'), (1, 20, '3'), (1, 21, '3');

-- Group 6: Comments and Suggestions (text responses)
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(1, 22, 'Learned about innovative ideas from different teams'),
(1, 23, 'The competition format was engaging'),
(1, 24, 'Some presentations ran too long'),
(1, 25, 'Maybe have stricter time limits for pitches next time');

-- Responses for Geraldine Aris (user_id: 5fb95ed0a0d20daf) for event 1001
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 1, '3'), (2, 2, '3'), (2, 3, '4'), (2, 4, '3'), (2, 5, '4'), 
(2, 6, '2'), (2, 7, '4'), (2, 8, '3'), (2, 9, '3'), (2, 10, '3'), (2, 11, '3');

-- Group 2: Speaker questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 12, '4'), (2, 13, '3'), (2, 14, '4');

-- Group 3: Meals questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 15, '3'), (2, 16, '4');

-- Group 4: Handouts questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 17, '3'), (2, 18, '4');

-- Group 5: Transportation questions (marked as not applicable)
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 19, '1'), (2, 20, '1'), (2, 21, '1');

-- Group 6: Comments and Suggestions (text responses)
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(2, 22, 'Interesting to see different approaches to problem solving'),
(2, 23, 'The judging criteria were well explained'),
(2, 24, 'Some technical difficulties with presentations'),
(2, 25, 'Better AV setup would improve the experience');

-- Insert evaluations for event 1004 (Earth Hour Rally)
INSERT INTO tbl_evaluation (event_id, user_id, submitted_at, duration_seconds) VALUES
(1004, '5fb95ed0a0d20daf', '2025-06-15 10:40:00', 300),
(1004, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', '2025-06-15 10:35:00', 280),
(1004, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2025-06-15 10:30:00', 250);

-- Responses for Earth Hour Rally (only groups 1, 3, and 6 as per event config)
-- Geraldine Aris (user_id: 5fb95ed0a0d20daf)
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(3, 1, '4'), (3, 2, '4'), (3, 3, '4'), (3, 4, '4'), (3, 5, '4'), 
(3, 6, '4'), (3, 7, '4'), (3, 8, '4'), (3, 9, '4'), (3, 10, '4'), (3, 11, '4');

-- Group 3: Meals questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(3, 15, '4'), (3, 16, '4');

-- Group 6: Comments and Suggestions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(3, 22, 'Learned practical ways to help the environment'),
(3, 23, 'The hands-on activities were very engaging'),
(3, 24, 'Could have provided more water stations'),
(3, 25, 'More events like this please!');

-- Benson Javier (student) (user_id: 6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0)
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(4, 1, '3'), (4, 2, '3'), (4, 3, '4'), (4, 4, '3'), (4, 5, '4'), 
(4, 6, '3'), (4, 7, '4'), (4, 8, '3'), (4, 9, '4'), (4, 10, '3'), (4, 11, '3');

-- Group 3: Meals questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(4, 15, '3'), (4, 16, '3');

-- Group 6: Comments and Suggestions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(4, 22, 'Good to learn about local environmental issues'),
(4, 23, 'The tree planting was my favorite part'),
(4, 24, 'It was very hot during the cleanup'),
(4, 25, 'Maybe schedule earlier in the morning during summer');

-- Carl Falcon (user_id: cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k)
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(5, 1, '4'), (5, 2, '4'), (5, 3, '4'), (5, 4, '4'), (5, 5, '4'), 
(5, 6, '4'), (5, 7, '4'), (5, 8, '4'), (5, 9, '4'), (5, 10, '4'), (5, 11, '4');

-- Group 3: Meals questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(5, 15, '4'), (5, 16, '4');

-- Group 6: Comments and Suggestions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(5, 22, 'Valuable experience in community service'),
(5, 23, 'Well-organized event with clear instructions'),
(5, 24, 'More shade would have been nice'),
(5, 25, 'Consider providing hats or caps for participants');

-- Insert evaluations for event 2001 (2023 Tech Expo)
INSERT INTO tbl_evaluation (event_id, user_id, submitted_at, duration_seconds) VALUES
(2001, '900f929ec408cb4', '2023-03-10 17:20:00', 350),
(2001, '5fb95ed0a0d20daf', '2023-03-10 17:00:00', 320);

-- Responses for 2023 Tech Expo (groups 1, 2, 4, and 6 as per event config)
-- Benson Javier (user_id: 900f929ec408cb4)
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(6, 1, '4'), (6, 2, '4'), (6, 3, '4'), (6, 4, '4'), (6, 5, '4'), 
(6, 6, '4'), (6, 7, '4'), (6, 8, '4'), (6, 9, '4'), (6, 10, '4'), (6, 11, '4');

-- Group 2: Speaker questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(6, 12, '4'), (6, 13, '4'), (6, 14, '4');

-- Group 4: Handouts questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(6, 17, '4'), (6, 18, '4');

-- Group 6: Comments and Suggestions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(6, 22, 'Saw many emerging technologies that will be useful for my studies'),
(6, 23, 'The VR demonstrations were amazing'),
(6, 24, 'Some booths were too crowded'),
(6, 25, 'Maybe extend the duration next year');

-- Geraldine Aris (user_id: 5fb95ed0a0d20daf)
-- Group 1: Activity questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(7, 1, '3'), (7, 2, '3'), (7, 3, '4'), (7, 4, '3'), (7, 5, '4'), 
(7, 6, '3'), (7, 7, '4'), (7, 8, '3'), (7, 9, '3'), (7, 10, '3'), (7, 11, '3');

-- Group 2: Speaker questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(7, 12, '4'), (7, 13, '3'), (7, 14, '4');

-- Group 4: Handouts questions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(7, 17, '3'), (7, 18, '4');

-- Group 6: Comments and Suggestions
INSERT INTO tbl_evaluation_response (evaluation_id, question_id, response_value) VALUES
(7, 22, 'Interesting to see practical applications of classroom concepts'),
(7, 23, 'The AI demonstrations were particularly impressive'),
(7, 24, 'Some presenters were hard to understand'),
(7, 25, 'More seating areas would be helpful');

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


INSERT INTO tbl_application_period(start_date, end_date, start_time, end_time, is_active, created_by) 
VALUES(
"2025-05-24",
"2025-06-20",
"15:24:00",
"10:00:00",
1,
"6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0"
);

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
    status ENUM('Active', 'Pending', 'Archived') DEFAULT 'Active',
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
    remarks TEXT NULL,
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

CREATE TABLE tbl_archived_organization_members (
    archived_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    member_type ENUM('Member', 'Executive', 'Committee') NOT NULL,
    executive_role_id INT DEFAULT NULL,
    committee_id INT DEFAULT NULL,
    committee_role ENUM('Committee Head', 'Committee Officer') DEFAULT NULL,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_by VARCHAR(200) NOT NULL, 
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number),
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id),
    FOREIGN KEY (executive_role_id) REFERENCES tbl_executive_role(executive_role_id)
);

CREATE TABLE tbl_archived_committees (
    archive_id INT AUTO_INCREMENT PRIMARY KEY,
    original_committee_id INT NOT NULL,
    organization_id INT NOT NULL,
    cycle_number INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_by VARCHAR(200) NOT NULL,
    reason VARCHAR(255),
    FOREIGN KEY (organization_id, cycle_number) REFERENCES tbl_renewal_cycle(organization_id, cycle_number),
    FOREIGN KEY (archived_by) REFERENCES tbl_user(user_id)
);



CREATE TABLE tbl_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT NOT NULL,
    venue_type ENUM('Face to face', 'Online') DEFAULT 'face to face',
    venue VARCHAR(200) NULL,
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

CREATE TABLE tbl_event_evaluation_settings (
    event_id INT PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    start_time TIME NOT NULL,
    end_time TIME NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE
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
        -- Use e.is_open_to ENUM for access_type
        CASE 
            WHEN e.is_open_to = 'Open to all' THEN 'Open to All'
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
          e.is_open_to = 'Open to all'
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
        o.is_recruiting,
        o.membership_fee_amount,
        (
            -- Count only non-executive Active members
            SELECT COUNT(*) 
            FROM tbl_organization_members om
            WHERE om.organization_id = o.organization_id
              AND om.member_type != 'Executive'
              AND om.status = 'Active'
        ) + (
            -- Count committee members not already counted
            SELECT COUNT(DISTINCT cm.user_id)
            FROM tbl_committee c
            JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
            WHERE c.organization_id = o.organization_id
              AND cm.user_id NOT IN (
                  SELECT user_id 
                  FROM tbl_organization_members 
                  WHERE organization_id = o.organization_id
                    AND status = 'Active'
              )
        ) AS total_members,
        (
            SELECT GROUP_CONCAT(u.profile_picture ORDER BY RAND() SEPARATOR ',')
            FROM (
                SELECT u.profile_picture
                FROM tbl_organization_members om
                JOIN tbl_user u ON om.user_id = u.user_id
                WHERE om.organization_id = o.organization_id
                  AND om.status = 'Active'
                UNION
                SELECT u.profile_picture
                FROM tbl_committee_members cm
                JOIN tbl_user u ON cm.user_id = u.user_id
                JOIN tbl_committee c ON cm.committee_id = c.committee_id
                WHERE c.organization_id = o.organization_id
                LIMIT 4
            ) AS u
        ) AS member_profile_pictures,
        -- Return membership status instead of has_joined
        COALESCE(
            (SELECT om.status 
             FROM tbl_organization_members om 
             WHERE om.organization_id = o.organization_id 
               AND om.user_id = p_user_id
             LIMIT 1),
            (SELECT IF(COUNT(*) > 0, 'Active', NULL)
             FROM tbl_committee c
             JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
             WHERE c.organization_id = o.organization_id
               AND cm.user_id = p_user_id
            ),
            'Not Member'
        ) AS membership_status,
        (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'event_id', e.event_id,
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
                'f_name', u.f_name,
                'l_name', u.l_name,
                'profile_picture', u.profile_picture
            ))
            FROM tbl_organization_members om
            JOIN tbl_executive_role er ON om.executive_role_id = er.executive_role_id
            JOIN tbl_user u ON om.user_id = u.user_id
            WHERE om.organization_id = o.organization_id
            AND om.member_type = 'Executive'
            AND om.status = 'Active'
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
          e.is_open_to = 'Open to all'
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
    DECLARE v_is_student BOOLEAN DEFAULT FALSE;
    DECLARE v_conflict_user_email VARCHAR(50);

    -- Get student role ID
    SELECT role_id INTO v_student_role_id 
    FROM tbl_role 
    WHERE LOWER(role_name) = 'student';

    -- Get existing user details by email
    SELECT user_id, status, role_id 
    INTO v_existing_user_id, v_current_status, v_current_role_id
    FROM tbl_user 
    WHERE email = p_email;

    -- Check if student
    IF v_current_role_id IS NOT NULL THEN
        SET v_is_student = (v_current_role_id = v_student_role_id);
    END IF;

    -- Scenario 1: Existing user found by email
    IF v_existing_user_id IS NOT NULL THEN
        -- Handle user_id mismatch
        IF v_existing_user_id != p_azure_sub THEN
            -- Check if new azure_sub is already used by another account
            SELECT email INTO v_conflict_user_email
            FROM tbl_user
            WHERE user_id = p_azure_sub;
            
            IF v_conflict_user_email IS NOT NULL THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Account conflict detected: Azure account already in use';
            END IF;
            
            -- Safe to update user_id to new azure_sub
            UPDATE tbl_user 
            SET user_id = p_azure_sub
            WHERE email = p_email;
            
            SET v_existing_user_id = p_azure_sub;  -- Update local variable
        END IF;

        -- For non-students in pending status: activate and update names
        IF NOT v_is_student AND v_current_status = 'Pending' THEN
            UPDATE tbl_user 
            SET 
                f_name = p_f_name,
                l_name = p_l_name,
                status = 'Active'
            WHERE user_id = v_existing_user_id;
        -- For students: only update names if changed
        ELSE
            UPDATE tbl_user 
            SET 
                f_name = p_f_name,
                l_name = p_l_name
            WHERE user_id = v_existing_user_id
            AND (f_name != p_f_name OR l_name != p_l_name);
        END IF;
    ELSE
        -- Check if azure_sub already exists with different email
        SELECT email INTO v_conflict_user_email
        FROM tbl_user
        WHERE user_id = p_azure_sub;
        
        IF v_conflict_user_email IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Account conflict detected: Azure account already in use';
        END IF;
        
        -- New user: create as active student
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
    IF p_status = 'Approved' THEN
        -- Only show upcoming or ongoing approved events
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
            (e.end_date > CURDATE())
            OR (e.end_date = CURDATE() AND e.end_time >= CURTIME())
            OR (e.end_date IS NULL AND e.start_date >= CURDATE())
          );
    ELSE
        -- For Pending or Rejected, show all regardless of date
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
        WHERE e.status = p_status;
    END IF;
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
            JOIN tbl_executive_role er ON om.executive_role_id = er.executive_role_id
            JOIN tbl_executive_rank erk ON er.rank_id = erk.rank_id
            JOIN tbl_user u ON om.user_id = u.user_id
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

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventEvaluationResponses(
    IN p_event_id INT
)
BEGIN
    -- Get all evaluation responses for the specified event
    SELECT 
        u.user_id,
        CONCAT(u.f_name, ' ', u.l_name) AS attendee_name,
        qg.group_title,
        q.question_id,
        q.question_text,
        q.question_type,
        r.response_value,
        r.created_at AS response_time,
        e.submitted_at AS evaluation_submission_time
    FROM 
        tbl_evaluation e
    JOIN 
        tbl_user u ON e.user_id = u.user_id
    JOIN 
        tbl_evaluation_response r ON e.evaluation_id = r.evaluation_id
    JOIN 
        tbl_evaluation_question q ON r.question_id = q.question_id
    JOIN 
        tbl_evaluation_question_group qg ON q.group_id = qg.group_id
    WHERE 
        e.event_id = p_event_id
    ORDER BY 
        u.l_name, u.f_name, qg.group_id, q.question_id;
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
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationsWeb(IN p_user_id VARCHAR(200))
BEGIN
    DECLARE v_user_role VARCHAR(100);
    
    -- Get user's role
    SELECT r.role_name INTO v_user_role
    FROM tbl_user u
    JOIN tbl_role r ON u.role_id = r.role_id
    WHERE u.user_id = p_user_id;
    
    -- Handle different roles
    IF v_user_role = 'Student' THEN
        -- For Students: Get their organizations with membership status
        SELECT 
            o.organization_id,
            o.name AS organization_name,
            o.logo AS organization_logo,
            o.status AS organization_status,
            o.category,
            p.name AS program_name,
            o.created_at,
            MAX(om.joined_at) AS last_joined_at,
            IF(MAX(om.joined_at) IS NOT NULL, 'Active', 'Not Member') AS membership_status
        FROM tbl_organization o
        LEFT JOIN tbl_program p ON o.base_program_id = p.program_id
        LEFT JOIN tbl_organization_members om 
            ON o.organization_id = om.organization_id 
            AND om.user_id = p_user_id
        WHERE o.status = 'Approved'
        GROUP BY o.organization_id
        ORDER BY o.created_at DESC;
        
    ELSEIF v_user_role = 'Adviser' THEN
        -- For Advisers: Get organizations they advise
        SELECT 
            o.organization_id,
            o.name AS organization_name,
            o.logo AS organization_logo,
            o.status AS organization_status,
            o.category,
            p.name AS program_name,
            o.created_at,
            'Adviser' AS role_in_org
        FROM tbl_organization o
        LEFT JOIN tbl_program p ON o.base_program_id = p.program_id
        WHERE o.adviser_id = p_user_id
        ORDER BY o.created_at DESC;
        
    ELSEIF v_user_role = 'Program Chair' THEN
        -- For Program Chairs: Get organizations in their program
        SELECT 
            o.organization_id,
            o.name AS organization_name,
            o.logo AS organization_logo,
            o.status AS organization_status,
            o.category,
            p.name AS program_name,
            o.created_at,
            'Program Chair' AS role_in_org
        FROM tbl_organization o
        JOIN tbl_program p ON o.base_program_id = p.program_id
        JOIN tbl_user u ON u.program_id = p.program_id
        WHERE u.user_id = p_user_id 
          AND o.status = 'Approved'
        ORDER BY o.created_at DESC;
        
    ELSE
        -- For all other roles: Get all approved organizations
        SELECT 
            o.organization_id,
            o.name AS organization_name,
            o.logo AS organization_logo,
            o.status AS organization_status,
            o.category,
            p.name AS program_name,
            o.created_at,
            'Viewer' AS role_in_org
        FROM tbl_organization o
        LEFT JOIN tbl_program p ON o.base_program_id = p.program_id
        WHERE o.status = 'Approved'
        ORDER BY o.created_at DESC;
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

    DECLARE v_unavailable_emails JSON;

    -- Create a temporary table to hold the emails
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_emails (
        email VARCHAR(255) NOT NULL,
        PRIMARY KEY (email)  -- Ensures uniqueness
    );

    -- Insert from first condition: non-student roles
    INSERT IGNORE INTO temp_emails (email)
    SELECT u.email
    FROM tbl_user u
    JOIN tbl_role r ON u.role_id = r.role_id
    WHERE 
        JSON_CONTAINS(p_emails, CAST(CONCAT('"', u.email, '"') AS JSON))
        AND LOWER(r.role_name) != 'student';

    -- Insert from second condition: executives
    INSERT IGNORE INTO temp_emails (email)
    SELECT u.email
    FROM tbl_user u
    JOIN tbl_organization_members om ON u.user_id = om.user_id
    WHERE 
        JSON_CONTAINS(p_emails, CAST(CONCAT('"', u.email, '"') AS JSON))
        AND om.member_type = 'Executive';

    -- Aggregate distinct emails
    SELECT COALESCE(JSON_ARRAYAGG(email), JSON_ARRAY())
    INTO v_unavailable_emails
    FROM temp_emails;

    -- Cleanup temporary table
    DROP TEMPORARY TABLE IF EXISTS temp_emails;

    SELECT JSON_OBJECT('unavailable', v_unavailable_emails) AS result;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetAllEventCertificates(IN
    p_user_id VARCHAR(200))
BEGIN
    SELECT 
        ec.*,
        e.title AS event_title,
        e.certificate AS certificate_type
    FROM tbl_event_certificate ec
    JOIN tbl_event e ON ec.event_id = e.event_id
    WHERE ec.user_id = p_user_id
    ORDER BY ec.issued_at DESC;
END $$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationDetails(IN p_org_name VARCHAR(100))
BEGIN
    -- Get organization ID and current cycle
    SET @org_id = (SELECT organization_id FROM tbl_organization WHERE name = p_org_name);
    SET @current_cycle = (
        SELECT MAX(cycle_number)
        FROM tbl_renewal_cycle
        WHERE organization_id = @org_id
    );

    -- Return organization data as JSON
    SELECT JSON_OBJECT(
        'organization_detail', JSON_OBJECT(
            'id', o.organization_id,
            'org_name', o.name,
            'category', o.category,
            'logo', o.logo,
            'description', o.description,
            'adviser', JSON_OBJECT(
                'first_name', adv.f_name,
                'last_name', adv.l_name,
                'email', adv.email
            )
        ),
        'members', (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'member_id', om.member_id,
                'first_name', u.f_name,
                'last_name', u.l_name,
                'email', u.email,
                'joined_at', om.joined_at
            ))
            FROM tbl_organization_members om
            JOIN tbl_user u ON om.user_id = u.user_id
            WHERE om.organization_id = @org_id
                AND om.cycle_number = @current_cycle
                -- Only include Active members
                AND om.status = 'Active'
                -- Exclude Executive members
                AND om.member_type != 'Executive'
                -- Exclude Committee members
                AND NOT EXISTS (
                    SELECT 1
                    FROM tbl_committee_members cm
                    JOIN tbl_committee c ON cm.committee_id = c.committee_id
                    WHERE c.organization_id = @org_id
                        AND c.cycle_number = @current_cycle
                        AND cm.user_id = om.user_id
                )
        ),
        'executive_members', (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'first_name', u.f_name,
                'last_name', u.l_name,
                'email', u.email,
                'role_title', er.role_title,
                'program_name', p.name
            ))
            FROM tbl_organization_members om
            JOIN tbl_user u ON om.user_id = u.user_id
            JOIN tbl_executive_role er ON om.executive_role_id = er.executive_role_id
            LEFT JOIN tbl_program p ON u.program_id = p.program_id
            WHERE om.organization_id = @org_id
                AND om.cycle_number = @current_cycle
                AND om.member_type = 'Executive'
        ),
        'committee_members', (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'first_name', u.f_name,
                'last_name', u.l_name,
                'email', u.email,
                'committee_name', c.name,
                'committee_role', cm.role
            ))
            FROM tbl_committee_members cm
            JOIN tbl_committee c ON cm.committee_id = c.committee_id
            JOIN tbl_user u ON cm.user_id = u.user_id
            WHERE c.organization_id = @org_id
                AND c.cycle_number = @current_cycle
        ),
        'committee_roles', (
            SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'committee_name', c.name,
                'role_name', cr.role_name
            ))
            FROM tbl_committee_role cr
            JOIN tbl_committee c ON cr.committee_id = c.committee_id
            WHERE c.organization_id = @org_id
                AND c.cycle_number = @current_cycle
        )
    ) AS result
    FROM tbl_organization o
    JOIN tbl_user adv ON o.adviser_id = adv.user_id
    WHERE o.organization_id = @org_id;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationQuestion(
    IN p_org_id INT
)
BEGIN
    SELECT * FROM tbl_membership_question WHERE organization_id =p_org_id;
END$$

DELIMITER ;


DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEventApplicationDetails(
    IN p_event_application_id INT
)
BEGIN
    -- Get basic event application information
    SELECT 
        ea.event_application_id,
        ea.organization_id,
        o.name AS organization_name,
        o.adviser_id,
        CONCAT(adviser.f_name, ' ', adviser.l_name) AS adviser_name,
        ea.cycle_number,
        rc.start_date AS cycle_start_date,
        ea.proposed_event_id,
        e.title,
        e.description,
        e.venue_type,
        e.venue,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.status AS event_status,
        e.type,
        e.is_open_to,
        e.fee,
        e.capacity,
        e.created_at AS event_created_at,
        ea.applicant_user_id,
        CONCAT(applicant.f_name, ' ', applicant.l_name) AS applicant_name,
        applicant.email AS applicant_email,
        ea.status AS application_status,
        ea.created_at AS application_created_at,
        ea.updated_at AS application_updated_at
    FROM tbl_event_application ea
    JOIN tbl_organization o ON ea.organization_id = o.organization_id
    LEFT JOIN tbl_event e ON ea.proposed_event_id = e.event_id
    JOIN tbl_renewal_cycle rc ON ea.organization_id = rc.organization_id 
        AND ea.cycle_number = rc.cycle_number
    JOIN tbl_user applicant ON ea.applicant_user_id = applicant.user_id
    JOIN tbl_user adviser ON o.adviser_id = adviser.user_id
    WHERE ea.event_application_id = p_event_application_id;
    
    -- Get all submitted requirements for this application
    SELECT 
        ers.submission_id,
        ers.requirement_id,
        ear.requirement_name,
        ear.is_applicable_to,
        ers.file_path,
        ers.submitted_by,
        CONCAT(u.f_name, ' ', u.l_name) AS submitted_by_name,
        ers.submitted_at
    FROM tbl_event_requirement_submissions ers
    JOIN tbl_event_application_requirement ear ON ers.requirement_id = ear.requirement_id
    JOIN tbl_user u ON ers.submitted_by = u.user_id
    WHERE ers.event_application_id = p_event_application_id
    ORDER BY ear.is_applicable_to, ear.requirement_name;
    
    -- Get all approval steps and statuses
    SELECT 
        eap.event_approval_id,
        eap.approver_id,
        CONCAT(u.f_name, ' ', u.l_name) AS approver_name,
        u.email AS approver_email,
        r.role_name,
        r.role_id,
        eap.approval_role_id,
        eap.status AS approval_status,
        eap.comment,
        eap.step_number,
        eap.approved_at
    FROM tbl_event_approval_process eap
    JOIN tbl_user u ON eap.approver_id = u.user_id
    JOIN tbl_role r ON eap.approval_role_id = r.role_id
    WHERE eap.event_application_id = p_event_application_id
    ORDER BY eap.step_number;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE CreateEventApplication(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_applicant_user_id VARCHAR(200),
    IN p_event JSON,
    IN p_requirements JSON
)
BEGIN
    DECLARE v_event_application_id INT;
    DECLARE v_event_id INT;
    DECLARE i INT DEFAULT 0;
    DECLARE v_requirement_count INT;
    DECLARE v_req_id INT;
    DECLARE v_file_path VARCHAR(255);
    DECLARE v_error_msg VARCHAR(255);
    DECLARE v_president_id VARCHAR(200);
    DECLARE v_first_step INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validate organization exists and user is authorized
    -- IF NOT EXISTS (
--         SELECT 1 FROM tbl_organization 
--         WHERE organization_id = p_organization_id
--     ) THEN
--         SIGNAL SQLSTATE '45000' 
--         SET MESSAGE_TEXT = 'Organization not found';
--     END IF;

    -- Validate user exists and belongs to organization
    -- IF NOT EXISTS (
--         SELECT 1 FROM tbl_user 
--         WHERE user_id = p_applicant_user_id
--     ) THEN
--         SIGNAL SQLSTATE '45000' 
--         SET MESSAGE_TEXT = 'User not found';
--     END IF;

    -- Check/create renewal cycle if needed
    IF NOT EXISTS (
        SELECT 1 FROM tbl_renewal_cycle 
        WHERE organization_id = p_organization_id 
        AND cycle_number = p_cycle_number
    ) THEN
        -- Get current president for the organization
        SELECT president_id INTO v_president_id
        FROM tbl_renewal_cycle
        WHERE organization_id = p_organization_id
        ORDER BY cycle_number DESC
        LIMIT 1;
        
        IF v_president_id IS NULL THEN
            SET v_president_id = p_applicant_user_id; -- Fallback to applicant if no president found
        END IF;

        INSERT INTO tbl_renewal_cycle (
            organization_id,
            cycle_number,
            president_id
        ) VALUES (
            p_organization_id,
            p_cycle_number,
            v_president_id
        );
    END IF;

    -- Create event record
    INSERT INTO tbl_event (
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
        capacity
    ) VALUES (
        p_organization_id,
        p_applicant_user_id,
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.title')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.description')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.venue_type')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.venue')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.start_date')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.end_date')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.start_time')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.end_time')),
        'Pending',
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.type')),
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.is_open_to')),
        CASE
            WHEN JSON_EXTRACT(p_event, '$.fee') IS NULL 
                 OR JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.fee')) = 'null'
                THEN NULL
            ELSE CAST(JSON_EXTRACT(p_event, '$.fee') AS UNSIGNED)
        END,
        CASE
            WHEN JSON_EXTRACT(p_event, '$.capacity') IS NULL 
                 OR JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.capacity')) = 'null'
                THEN NULL
            ELSE CAST(JSON_EXTRACT(p_event, '$.capacity') AS UNSIGNED)
        END
    );

    SET v_event_id = LAST_INSERT_ID();

    -- Create event application record
    INSERT INTO tbl_event_application (
        organization_id,
        cycle_number,
        proposed_event_id,
        applicant_user_id,
        status
    ) VALUES (
        p_organization_id,
        p_cycle_number,
        v_event_id,
        p_applicant_user_id,
        'Pending'
    );

    SET v_event_application_id = LAST_INSERT_ID();

    -- Handle requirements
    SET v_requirement_count = JSON_LENGTH(p_requirements);
    SET i = 0;
    
    WHILE i < v_requirement_count DO
        BEGIN
            DECLARE v_requirement_exists TINYINT(1);
            
            SET v_req_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].requirement_id'))) AS UNSIGNED);
            SET v_file_path = JSON_UNQUOTE(JSON_EXTRACT(p_requirements, CONCAT('$[', i, '].file_path')));
            
            -- Validate requirement exists
            SELECT EXISTS(
                SELECT 1 FROM tbl_event_application_requirement 
                WHERE requirement_id = v_req_id
            ) INTO v_requirement_exists;
            
            IF NOT v_requirement_exists THEN
                SET v_error_msg = CONCAT('Invalid requirement ID: ', v_req_id);
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
            END IF;
            
            -- Store requirement submission
            INSERT INTO tbl_event_requirement_submissions (
                event_id,
                event_application_id,
                requirement_id,
                cycle_number,
                organization_id,
                file_path,
                submitted_by
            ) VALUES (
                v_event_id,
                v_event_application_id,
                v_req_id,
                p_cycle_number,
                p_organization_id,
                v_file_path,
                p_applicant_user_id
            );

            SET i = i + 1;
        END;
    END WHILE;

    -- Initiate approval process
    CALL InitiateEventApprovalProcess(v_event_application_id);

    COMMIT;

    -- Return success information
    SELECT 
        v_event_id AS event_id,
        v_event_application_id AS event_application_id,
        JSON_UNQUOTE(JSON_EXTRACT(p_event, '$.title')) AS event_title,
        p_organization_id AS organization_id,
        p_cycle_number AS cycle_number;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE `InitiateEventApprovalProcess`(IN p_event_application_id INT)
BEGIN
    DECLARE v_org_id INT;
    DECLARE v_program_id INT;
    DECLARE v_adviser_id VARCHAR(200);
    DECLARE v_role_id INT;
    DECLARE v_hierarchy_order INT;
    DECLARE v_approver_id VARCHAR(200);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE step_counter INT DEFAULT 0;
    DECLARE v_approvers_found INT DEFAULT 0;

    -- Get organization details first
    SELECT 
        o.organization_id, 
        o.base_program_id, 
        o.adviser_id
    INTO 
        v_org_id, 
        v_program_id, 
        v_adviser_id
    FROM tbl_event_application ea
    JOIN tbl_organization o ON ea.organization_id = o.organization_id
    WHERE ea.event_application_id = p_event_application_id;

    -- Debug: Check if we got organization details
    IF v_org_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization not found for this application';
    END IF;

    -- Debug: Check if adviser exists
    IF v_adviser_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization has no assigned adviser';
    END IF;

    -- Validate Adviser exists and has correct role
    IF NOT EXISTS (
        SELECT 1 FROM tbl_user 
        WHERE user_id = v_adviser_id 
        AND role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'Adviser')
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization adviser must have Adviser role';
    END IF;

    -- Get all approver roles (excluding applicant)
    BEGIN
        DECLARE role_cursor CURSOR FOR
            SELECT r.role_id, r.hierarchy_order
            FROM tbl_role r
            WHERE r.is_approver = 1
            AND r.hierarchy_order IS NOT NULL
            AND r.hierarchy_order >= 1  -- Changed from > 1 to >= 1 to include Adviser
            ORDER BY r.hierarchy_order;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

        OPEN role_cursor;

        role_loop: LOOP
            FETCH role_cursor INTO v_role_id, v_hierarchy_order;
            IF done THEN
                LEAVE role_loop;
            END IF;

            -- Find approver based on role
            IF v_role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'Adviser') THEN
                -- Use organization's adviser
                SET v_approver_id = v_adviser_id;
                SET v_approvers_found = v_approvers_found + 1;
            ELSEIF v_role_id = (SELECT role_id FROM tbl_role WHERE role_name = 'Program Chair') THEN
                -- Find program chair for this organization's program
                SELECT user_id INTO v_approver_id
                FROM tbl_user
                WHERE role_id = v_role_id
                AND program_id = v_program_id
                LIMIT 1;
                
                IF v_approver_id IS NOT NULL THEN
                    SET v_approvers_found = v_approvers_found + 1;
                END IF;
            ELSE
                -- For other roles (like OSA Director, etc.)
                SELECT user_id INTO v_approver_id
                FROM tbl_user
                WHERE role_id = v_role_id
                LIMIT 1;
                
                IF v_approver_id IS NOT NULL THEN
                    SET v_approvers_found = v_approvers_found + 1;
                END IF;
            END IF;

            -- Insert approval step if we found an approver
            IF v_approver_id IS NOT NULL THEN
                INSERT INTO tbl_event_approval_process (
                    event_application_id,
                    approver_id,
                    approval_role_id,
                    status,
                    step_number
                ) VALUES (
                    p_event_application_id,
                    v_approver_id,
                    v_role_id,
                    'Pending',  -- All steps require manual approval
                    v_hierarchy_order
                );
            END IF;
            
            SET v_approver_id = NULL; -- Reset for next iteration
        END LOOP role_loop;

        CLOSE role_cursor;
    END;

    -- Validate we created at least one approval step
    IF v_approvers_found = 0 THEN
        -- Debug information
        SELECT 
            v_org_id AS org_id,
            v_program_id AS program_id,
            v_adviser_id AS adviser_id,
            (SELECT COUNT(*) FROM tbl_role WHERE is_approver = 1 AND hierarchy_order > 1) AS approver_roles_count,
            (SELECT COUNT(*) FROM tbl_user WHERE role_id IN 
                (SELECT role_id FROM tbl_role WHERE is_approver = 1 AND hierarchy_order > 1)
            ) AS approvers_count;
            
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No valid approvers found for any approval steps';
    END IF;
END$$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ApproveEventApplication(
    IN p_approval_id INT,
    IN p_comment TEXT,
    IN p_event_application_id INT,
    IN p_user_id VARCHAR(200))
BEGIN
    DECLARE v_step_number INT;
    DECLARE v_max_step INT;
    DECLARE v_event_id INT;
    DECLARE v_organization_id INT;
    DECLARE v_event_title VARCHAR(300);
    DECLARE v_end_date DATE;
    DECLARE v_end_time TIME;
    
    -- Update the approval status
    UPDATE tbl_event_approval_process
    SET 
        comment = p_comment,
        status = 'Approved',
        approved_at = CURRENT_TIMESTAMP
    WHERE event_approval_id = p_approval_id;
    
    -- Log the approval action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data
    ) VALUES (
        p_user_id,
        CONCAT('Approved event application step for application ID: ', p_event_application_id),
        'Event Approval',
        JSON_OBJECT(
            'approval_id', p_approval_id,
            'application_id', p_event_application_id,
            'comment', p_comment
        )
    );
    
    -- Get current step number
    SELECT step_number INTO v_step_number
    FROM tbl_event_approval_process
    WHERE event_approval_id = p_approval_id;
    
    -- Get the max step number for this application
    SELECT MAX(step_number) INTO v_max_step
    FROM tbl_event_approval_process
    WHERE event_application_id = p_event_application_id;
    
    -- Check if this is the final approval
    IF v_step_number = v_max_step THEN
        -- Get the proposed event ID and organization ID
        SELECT e.proposed_event_id, e.organization_id, ev.title, ev.end_date, ev.end_time
        INTO v_event_id, v_organization_id, v_event_title, v_end_date, v_end_time
        FROM tbl_event_application e
        LEFT JOIN tbl_event ev ON e.proposed_event_id = ev.event_id
        WHERE e.event_application_id = p_event_application_id;
        
        -- Update event application status
        UPDATE tbl_event_application
        SET status = 'Approved',
            updated_at = CURRENT_TIMESTAMP
        WHERE event_application_id = p_event_application_id;
        
        -- Update the event status if it exists
        IF v_event_id IS NOT NULL THEN
            UPDATE tbl_event
            SET status = 'Approved'
            WHERE event_id = v_event_id;
            
            -- Create evaluation settings with default configuration
            INSERT INTO tbl_event_evaluation_settings (
                event_id,
                start_date,
                start_time,
                is_active
            ) VALUES (
                v_event_id,
                v_end_date,
                v_end_time,
                TRUE
            );
            
            -- Add default evaluation configuration (group 1 - Activity questions)
            INSERT INTO tbl_event_evaluation_config (event_id, group_id)
            VALUES (v_event_id, 1);
            
            -- Log evaluation setup
            INSERT INTO tbl_logs (
                user_id,
                action,
                type,
                meta_data
            ) VALUES (
                p_user_id,
                CONCAT('Added default evaluation configuration for event: ', v_event_title),
                'Event Evaluation Setup',
                JSON_OBJECT(
                    'event_id', v_event_id,
                    'default_group_id', 1
                )
            );
        END IF;
        
        -- Log final approval
        INSERT INTO tbl_logs (
            user_id,
            action,
            type,
            meta_data
        ) VALUES (
            p_user_id,
            CONCAT('Fully approved event application for: ', IFNULL(v_event_title, 'Untitled Event')),
            'Event Final Approval',
            JSON_OBJECT(
                'application_id', p_event_application_id,
                'event_id', IFNULL(v_event_id, 'NULL'),
                'organization_id', v_organization_id
            )
        );
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE RejectEventApplication(
    IN p_approval_id INT,
    IN p_event_application_id INT,
    IN p_comment TEXT,
    IN p_user_id VARCHAR(200)  -- Added user_id parameter for logging
)
BEGIN
    DECLARE v_event_id INT;
    DECLARE v_event_title VARCHAR(300);
    
    START TRANSACTION;
    
    -- Update the approval status
    UPDATE tbl_event_approval_process
    SET 
        status = 'Rejected',
        comment = p_comment,
        approved_at = CURRENT_TIMESTAMP
    WHERE event_approval_id = p_approval_id;
    
    -- Get the proposed event ID and title
    SELECT e.proposed_event_id, ev.title INTO v_event_id, v_event_title
    FROM tbl_event_application e
    LEFT JOIN tbl_event ev ON e.proposed_event_id = ev.event_id
    WHERE e.event_application_id = p_event_application_id;
    
    -- Update event application status
    UPDATE tbl_event_application
    SET status = 'Rejected',
        updated_at = CURRENT_TIMESTAMP
    WHERE event_application_id = p_event_application_id;
    
    -- Update the event status if it exists
    IF v_event_id IS NOT NULL THEN
        UPDATE tbl_event
        SET status = 'Rejected'
        WHERE event_id = v_event_id;
    END IF;
    
    -- Log the rejection
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data
    ) VALUES (
        p_user_id,
        CONCAT('Rejected event application for: ', IFNULL(v_event_title, 'Untitled Event')),
        'Event Rejection',
        JSON_OBJECT(
            'approval_id', p_approval_id,
            'application_id', p_event_application_id,
            'event_id', IFNULL(v_event_id, 'NULL'),
            'comment', p_comment
        )
    );
    
    COMMIT;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetEventEvaluationConfig(IN p_event_id INT)
BEGIN
    -- Get evaluation settings
    SELECT 
        es.event_id,
        e.title,
        es.start_date AS evaluation_start_date,
        es.end_date AS evaluation_end_date,
        es.start_time AS evaluation_start_time,
        es.end_time AS evaluation_end_time,
        es.is_active
    FROM tbl_event_evaluation_settings es
    JOIN tbl_event e ON es.event_id = e.event_id
    WHERE es.event_id = p_event_id;
    
    -- Get enabled question groups for this event
    SELECT 
        g.group_id,
        g.group_title,
        g.group_description
    FROM tbl_event_evaluation_config ec
    JOIN tbl_evaluation_question_group g ON ec.group_id = g.group_id
    WHERE ec.event_id = p_event_id
    AND g.is_active = TRUE;
    
    -- Get all available question groups (for adding to configuration)
    SELECT 
        group_id,
        group_title,
        group_description
    FROM tbl_evaluation_question_group
    WHERE is_active = TRUE;
END$$
DELIMITER ;

SELECT * FROM db_nuconnect.tbl_event_evaluation_settings;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE UpdateEventEvaluationConfig(
    IN p_event_id INT,
    IN p_group_ids JSON,
    IN p_evaluation_end_date DATE,
    IN p_evaluation_end_time TIME,
    IN p_user_id VARCHAR(200))
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE group_count INT;
    DECLARE current_group_id INT;
    
    -- First, clear existing configuration for this event
    DELETE FROM tbl_event_evaluation_config WHERE event_id = p_event_id;
    
    -- Get the count of groups to add
    SET group_count = JSON_LENGTH(p_group_ids);
    
    -- Add each group in the JSON array
    WHILE i < group_count DO
        SET current_group_id = JSON_EXTRACT(p_group_ids, CONCAT('$[', i, ']'));
        
        INSERT INTO tbl_event_evaluation_config (event_id, group_id)
        VALUES (p_event_id, current_group_id);
        
        SET i = i + 1;
    END WHILE;
    
    -- Update evaluation end date/time if provided
    IF p_evaluation_end_date IS NOT NULL AND p_evaluation_end_time IS NOT NULL THEN
        UPDATE tbl_event_evaluation_settings
        SET end_date = p_evaluation_end_date,
            end_time = p_evaluation_end_time
        WHERE event_id = p_event_id;
    END IF;
    
    -- Log the configuration update
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data
    ) VALUES (
        p_user_id,
        CONCAT('Updated evaluation configuration for event ID: ', p_event_id),
        'Event Evaluation Config',
        JSON_OBJECT(
            'event_id', p_event_id,
            'group_ids', p_group_ids,
            'evaluation_end_date', IFNULL(p_evaluation_end_date, 'NULL'),
            'evaluation_end_time', IFNULL(p_evaluation_end_time, 'NULL')
        )
    );
END$$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE UploadOrUpdatePostEventRequirement(
    IN p_event_id INT,
    IN p_event_application_id INT,
    IN p_requirement_id INT,
    IN p_cycle_number INT,
    IN p_organization_id INT,
    IN p_file_path VARCHAR(255),
    IN p_submitted_by VARCHAR(200)
)
BEGIN
    -- All DECLAREs must be here, before any other statement!
    DECLARE v_event_application_id INT;
    DECLARE v_submission_id INT;

    -- Lookup event_application_id if not provided
    IF p_event_application_id IS NULL OR p_event_application_id = 0 THEN
        SELECT event_application_id INTO v_event_application_id
        FROM tbl_event_application
        WHERE proposed_event_id = p_event_id
        LIMIT 1;
    ELSE
        SET v_event_application_id = p_event_application_id;
    END IF;

    -- Check if a submission already exists for this event, requirement, and user
    SELECT submission_id INTO v_submission_id
    FROM tbl_event_requirement_submissions
    WHERE event_id = p_event_id
      AND event_application_id = v_event_application_id
      AND requirement_id = p_requirement_id
      AND submitted_by = p_submitted_by
    LIMIT 1;

    IF v_submission_id IS NOT NULL THEN
        -- Update the existing submission
        UPDATE tbl_event_requirement_submissions
        SET file_path = p_file_path,
            submitted_at = CURRENT_TIMESTAMP
        WHERE submission_id = v_submission_id;
    ELSE
        -- Insert a new submission
        INSERT INTO tbl_event_requirement_submissions (
            event_id,
            event_application_id,
            requirement_id,
            cycle_number,
            organization_id,
            file_path,
            submitted_by
        ) VALUES (
            p_event_id,
            v_event_application_id,
            p_requirement_id,
            p_cycle_number,
            p_organization_id,
            p_file_path,
            p_submitted_by
        );
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventRequirementSubmissions(
    IN p_event_id INT,
    IN p_event_application_id INT,
    IN p_requirement_id INT,
    IN p_submitted_by VARCHAR(200)
)
BEGIN
    SELECT
        ers.submission_id,
        ers.event_id,
        e.title AS event_title,
        ers.event_application_id,
        ea.organization_id,
        ea.cycle_number,
        ers.requirement_id,
        req.requirement_name,
        req.is_applicable_to,
        ers.file_path,
        ers.submitted_by,
        u.f_name,
        u.l_name,
        u.email,
        ers.submitted_at
    FROM tbl_event_requirement_submissions ers
    LEFT JOIN tbl_event_application ea ON ers.event_application_id = ea.event_application_id
    LEFT JOIN tbl_event_application_requirement req ON ers.requirement_id = req.requirement_id
    LEFT JOIN tbl_user u ON ers.submitted_by = u.user_id
    LEFT JOIN tbl_event e ON ers.event_id = e.event_id
    WHERE ers.event_id = p_event_id
      AND (p_event_application_id IS NULL OR ers.event_application_id = p_event_application_id)
      AND (p_requirement_id IS NULL OR ers.requirement_id = p_requirement_id)
      AND (p_submitted_by IS NULL OR ers.submitted_by = p_submitted_by)
    ORDER BY ers.submitted_at DESC;

END$$

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

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationsByStatus(
    IN p_status ENUM('Pending', 'Approved', 'Rejected', 'Renewal', 'Archived')
)
BEGIN
    SELECT 
        o.organization_id,
        o.adviser_id,
        o.name AS organization_name,
        o.description,
        o.base_program_id,
        o.logo,
        o.status,
        o.membership_fee_type,
        o.membership_fee_amount,
        o.is_recruiting,
        o.is_open_to_all_courses,
        o.category,
        o.created_at,
        -- Main/base program (if any)
        p.program_id AS base_program_id,
        p.name AS base_program_name,
        p.description AS base_program_description,
        -- All additional programs (if any, as JSON array)
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'program_id', pr.program_id,
                    'program_name', pr.name,
                    'program_description', pr.description
                )
            )
            FROM tbl_organization_course oc
            JOIN tbl_program pr ON oc.program_id = pr.program_id
            WHERE oc.organization_id = o.organization_id
        ) AS additional_programs
    FROM tbl_organization o
    LEFT JOIN tbl_program p ON o.base_program_id = p.program_id
    WHERE o.status = p_status
    ORDER BY o.created_at DESC;
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
    SET status = 'Archived'
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
    SET status = 'Approved'
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
                    'organization_name', o.name,
                    'category', o.category
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

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationFee(IN
    p_organization_id INT
)
BEGIN
    SELECT membership_fee_amount AS membership_fee FROM tbl_organization WHERE organization_id = p_organization_id;  
END $$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ApplyForMembership(
    IN p_org_id INT,
    IN p_user_id VARCHAR(200),
    IN p_payment_data JSON,
    IN p_question_id INT,
    IN p_response_value TEXT
)
BEGIN
    DECLARE v_cycle_number INT;
    DECLARE v_fee_type ENUM('Per Term', 'Whole Academic Year', 'Free');
    DECLARE v_fee_amount DECIMAL(10,2);
    DECLARE v_application_id INT;
    DECLARE error_msg TEXT;
    
    -- Get current renewal cycle
    SELECT MAX(cycle_number) INTO v_cycle_number
    FROM tbl_renewal_cycle 
    WHERE organization_id = p_org_id;
    
    IF v_cycle_number IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No active renewal cycle found for organization';
    END IF;

    -- Get organization fee details
    SELECT membership_fee_type, membership_fee_amount
    INTO v_fee_type, v_fee_amount
    FROM tbl_organization
    WHERE organization_id = p_org_id;

    -- Validate payment requirements
    IF v_fee_type != 'Free' AND v_fee_amount > 0 THEN
        IF p_payment_data IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payment is required for this organization';
        END IF;
        
        IF JSON_EXTRACT(p_payment_data, '$.membership_fee') != v_fee_amount THEN
            -- Fixed CONCAT syntax
            SET error_msg = CONCAT('Payment amount does not match organization fee. Required: ', v_fee_amount);
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = error_msg;
        END IF;
    END IF;

    -- Start transaction
    START TRANSACTION;
    
    -- Create membership application
    INSERT INTO tbl_membership_application (
        organization_id, 
        cycle_number, 
        user_id, 
        status
    )
    VALUES (
        p_org_id,
        v_cycle_number,
        p_user_id,
        'Pending'
    );
    
    SET v_application_id = LAST_INSERT_ID();
    
    -- Store custom question response
    INSERT INTO tbl_membership_response (
        application_id,
        question_id,
        response_value
    )
    VALUES (
        v_application_id,
        p_question_id,
        p_response_value
    );
    
    -- Create organization member record
    INSERT INTO tbl_organization_members (
        organization_id,
        cycle_number,
        user_id,
        member_type,
        status
    )
    VALUES (
        p_org_id,
        v_cycle_number,
        p_user_id,
        'Member',
        'Pending'
    );
    
    -- Process payment only if required and payment data exists
    IF p_payment_data IS NOT NULL AND JSON_EXTRACT(p_payment_data, '$.membership_fee') IS NOT NULL THEN
        -- Create transaction
        INSERT INTO tbl_transaction (
            user_id,
            amount,
            transaction_type,
            status,
            proof_image
        )
        VALUES (
            p_user_id,
            v_fee_amount,
            'Membership Fee',
            'Pending',
            JSON_UNQUOTE(JSON_EXTRACT(p_payment_data, '$.payment_proof'))
        );
        
        -- Link transaction to membership
        INSERT INTO tbl_transaction_membership (
            transaction_id,
            organization_id,
            cycle_number
        )
        VALUES (
            LAST_INSERT_ID(),
            p_org_id,
            v_cycle_number
        );
    END IF;
    
    -- Commit transaction
    COMMIT;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationEventApplications(
    IN p_org_name VARCHAR(100)
)
BEGIN
    DECLARE v_organization_id INT;

    -- Lookup organization_id from name
    SELECT organization_id INTO v_organization_id
    FROM tbl_organization
    WHERE name = p_org_name
    LIMIT 1;

    IF v_organization_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Organization not found';
    END IF;

    -- Get all event applications for the organization, with event and applicant details
    SELECT 
        ea.event_application_id,
        ea.organization_id,
        o.name AS organization_name,
        o.adviser_id,
        CONCAT(adviser.f_name, ' ', adviser.l_name) AS adviser_name,
        ea.cycle_number,
        rc.start_date AS cycle_start_date,
        ea.proposed_event_id,
        e.title AS event_title,
        e.description AS event_description,
        e.venue_type,
        e.venue,
        e.start_date,
        e.end_date,
        e.start_time,
        e.end_time,
        e.status AS event_status,
        e.type,
        e.is_open_to,
        e.fee,
        e.capacity,
        e.created_at AS event_created_at,
        ea.applicant_user_id,
        CONCAT(applicant.f_name, ' ', applicant.l_name) AS applicant_name,
        applicant.email AS applicant_email,
        ea.status AS application_status,
        ea.created_at AS application_created_at,
        ea.updated_at AS application_updated_at
    FROM tbl_event_application ea
    JOIN tbl_organization o ON ea.organization_id = o.organization_id
    LEFT JOIN tbl_event e ON ea.proposed_event_id = e.event_id
    JOIN tbl_renewal_cycle rc ON ea.organization_id = rc.organization_id 
        AND ea.cycle_number = rc.cycle_number
    JOIN tbl_user applicant ON ea.applicant_user_id = applicant.user_id
    JOIN tbl_user adviser ON o.adviser_id = adviser.user_id
    WHERE ea.organization_id = v_organization_id
    ORDER BY ea.created_at DESC;

    -- Get all submitted requirements/files for all applications of this organization
    SELECT 
        ers.submission_id,
        ers.event_application_id,
        ers.requirement_id,
        ear.requirement_name,
        ear.is_applicable_to,
        ers.file_path,
        ers.submitted_by,
        CONCAT(u.f_name, ' ', u.l_name) AS submitted_by_name,
        ers.submitted_at
    FROM tbl_event_requirement_submissions ers
    JOIN tbl_event_application_requirement ear ON ers.requirement_id = ear.requirement_id
    JOIN tbl_user u ON ers.submitted_by = u.user_id
    WHERE ers.organization_id = v_organization_id
    ORDER BY ers.event_application_id, ear.is_applicable_to, ear.requirement_name;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetEventRequirementSubmissionsByOrganization(
    IN p_organization_id INT
)
BEGIN
    SELECT
        ers.submission_id,
        ers.event_id,
        e.title AS event_title,
        ers.event_application_id,
        ers.cycle_number,
        ers.organization_id,
        o.name AS organization_name,
        ers.requirement_id,
        req.requirement_name,
        req.is_applicable_to,
        ers.file_path,
        ers.submitted_by,
        u.f_name AS submitted_by_first_name,
        u.l_name AS submitted_by_last_name,
        u.email AS submitted_by_email,
        ers.submitted_at
    FROM tbl_event_requirement_submissions ers
    LEFT JOIN tbl_event e ON ers.event_id = e.event_id
    LEFT JOIN tbl_organization o ON ers.organization_id = o.organization_id
    LEFT JOIN tbl_event_application_requirement req ON ers.requirement_id = req.requirement_id
    LEFT JOIN tbl_user u ON ers.submitted_by = u.user_id
    WHERE ers.organization_id = p_organization_id
    ORDER BY ers.submitted_at DESC;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationDashboardStats(
    IN p_organization_id INT
)
BEGIN
    DECLARE v_current_cycle INT;

    -- Get current cycle
    SELECT MAX(cycle_number) INTO v_current_cycle
    FROM tbl_renewal_cycle
    WHERE organization_id = p_organization_id;

    -- Total members (excluding executives and committee members)
    SELECT COUNT(*) INTO @total_members
    FROM tbl_organization_members om
    WHERE om.organization_id = p_organization_id
      AND om.cycle_number = v_current_cycle
      AND om.member_type = 'Member'
      AND NOT EXISTS (
          SELECT 1
          FROM tbl_committee_members cm
          JOIN tbl_committee c ON cm.committee_id = c.committee_id
          WHERE c.organization_id = p_organization_id
            AND c.cycle_number = v_current_cycle
            AND cm.user_id = om.user_id
      );

    -- Total events
    SELECT COUNT(*) INTO @total_events
    FROM tbl_event
    WHERE organization_id = p_organization_id;

    -- Total upcoming events
    SELECT COUNT(*) INTO @total_upcoming_events
    FROM tbl_event
    WHERE organization_id = p_organization_id
      AND start_date >= CURDATE();

    -- Total post-event reports submitted
    SELECT COUNT(*) INTO @total_reports
    FROM tbl_event_requirement_submissions ers
    JOIN tbl_event_application_requirement ear ON ers.requirement_id = ear.requirement_id
    WHERE ers.organization_id = p_organization_id
      AND ear.is_applicable_to = 'post-event';

    -- Total pre-event requirements submitted
    SELECT COUNT(*) INTO @pre_event_requirements_submitted
    FROM tbl_event_requirement_submissions ers
    JOIN tbl_event_application_requirement ear ON ers.requirement_id = ear.requirement_id
    WHERE ers.organization_id = p_organization_id
      AND ear.is_applicable_to = 'pre-event';

    -- Return as one row
    SELECT
        @total_members AS total_members,
        @total_events AS total_events,
        @total_reports AS total_reports,
        @pre_event_requirements_submitted AS pre_event_requirements_submitted,
        @total_upcoming_events AS total_upcoming_events;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE CreateSDAOEvent(
    IN p_organization_id INT,
    IN p_user_id VARCHAR(200),
    IN p_title VARCHAR(300),
    IN p_description TEXT,
    IN p_venue_type ENUM('Face to face', 'Online'),
    IN p_venue VARCHAR(200),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME,
    IN p_status ENUM('Pending', 'Approved', 'Rejected', 'Archived'),
    IN p_type ENUM('Paid', 'Free'),
    IN p_is_open_to ENUM('Members only', 'Open to all', 'NU Students only'),
    IN p_fee INT,
    IN p_capacity INT,
    IN p_certificate VARCHAR(1000)
)
BEGIN
    INSERT INTO tbl_event (
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
        certificate
    ) VALUES (
        p_organization_id,
        p_user_id,
        p_title,
        p_description,
        p_venue_type,
        p_venue,
        p_start_date,
        p_end_date,
        p_start_time,
        p_end_time,
        p_status,
        p_type,
        p_is_open_to,
        p_fee,
        p_capacity,
        p_certificate
    );

    SELECT * FROM tbl_event WHERE event_id = LAST_INSERT_ID();
END$$

DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CreateExecutiveMember(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_email VARCHAR(100),
    IN p_program_name VARCHAR(50),
    IN p_role_title VARCHAR(100),
    IN p_rank_level INT,
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_role_id INT;
    DECLARE v_executive_role_id INT;
    DECLARE v_rank_id INT;
    DECLARE v_organization_exists INT;
    DECLARE v_cycle_exists INT;
    DECLARE v_current_membership INT;
    DECLARE v_program_id INT;

    -- Look up program_id from program name
    SELECT program_id INTO v_program_id
    FROM tbl_program
    WHERE name = p_program_name
    LIMIT 1;

    IF v_program_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Program not found';
    END IF;

    -- Validate organization exists and is active
    SELECT COUNT(*) INTO v_organization_exists 
    FROM tbl_organization 
    WHERE organization_id = p_organization_id 
    AND status IN ('Approved', 'Renewal');
    
    IF v_organization_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization not found or not active';
    END IF;

    -- Validate renewal cycle exists
    SELECT COUNT(*) INTO v_cycle_exists 
    FROM tbl_renewal_cycle 
    WHERE organization_id = p_organization_id 
    AND cycle_number = p_cycle_number;
    
    IF v_cycle_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Renewal cycle not found';
    END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id 
    FROM tbl_user 
    WHERE email = p_action_by_email 
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Get role_id for 'Student'
    SELECT role_id INTO v_role_id 
    FROM tbl_role 
    WHERE LOWER(role_name) = 'student' 
    LIMIT 1;

    -- Check if user exists
    SELECT user_id INTO v_user_id 
    FROM tbl_user 
    WHERE email = p_email 
    LIMIT 1;

    -- Check if user is already a member in this cycle
    IF v_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current_membership
        FROM tbl_organization_members
        WHERE organization_id = p_organization_id
        AND cycle_number = p_cycle_number
        AND user_id = v_user_id;

        IF v_current_membership > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'User is already a member in this cycle';
        END IF;
    END IF;

    IF v_user_id IS NULL THEN
        -- Create new user with pending status
        SET v_user_id = CONCAT('usr-', UUID_SHORT());
        
        INSERT INTO tbl_user (
            user_id,
            email,
            role_id,
            program_id,
            status,
            created_at,
            updated_at
        ) VALUES (
            v_user_id,
            p_email,
            v_role_id,
            v_program_id,
            'Pending',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    -- Get rank_id from the specified rank level
    SELECT rank_id INTO v_rank_id 
    FROM tbl_executive_rank 
    WHERE rank_level = p_rank_level
    LIMIT 1;

    IF v_rank_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid rank level';
    END IF;

    -- Create executive role if not exists
    SELECT executive_role_id INTO v_executive_role_id
    FROM tbl_executive_role
    WHERE organization_id = p_organization_id
      AND cycle_number = p_cycle_number
      AND role_title = p_role_title
      AND rank_id = v_rank_id
    LIMIT 1;

    IF v_executive_role_id IS NULL THEN
        INSERT INTO tbl_executive_role (
            organization_id,
            cycle_number,
            role_title,
            rank_id,
            created_at
        ) VALUES (
            p_organization_id,
            p_cycle_number,
            p_role_title,
            v_rank_id,
            CURRENT_TIMESTAMP
        );
        
        SET v_executive_role_id = LAST_INSERT_ID();
    END IF;

    -- Insert into organization members as Executive
    INSERT INTO tbl_organization_members (
        organization_id, 
        cycle_number, 
        user_id, 
        member_type, 
        executive_role_id,
        joined_at
    ) VALUES (
        p_organization_id, 
        p_cycle_number, 
        v_user_id, 
        'Executive', 
        v_executive_role_id,
        CURRENT_TIMESTAMP
    );

    -- Log the action
    INSERT INTO tbl_logs (
        user_id, 
        action, 
        type, 
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Added executive member: ', v_user_id, ' (', p_email, ') as ', p_role_title),
        'executive_member',
        JSON_OBJECT(
            'organization_id', p_organization_id, 
            'cycle_number', p_cycle_number,
            'user_id', v_user_id, 
            'executive_role_id', v_executive_role_id,
            'role_title', p_role_title,
            'rank_level', p_rank_level,
            'program_id', v_program_id
        ),
        CURRENT_TIMESTAMP
    );
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE UpdateExecutiveMember(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_email VARCHAR(100),
    IN p_program_name VARCHAR(50),
    IN p_role_title VARCHAR(100),
    IN p_rank_level INT,
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_role_id INT;
    DECLARE v_rank_id INT;
    DECLARE v_executive_role_id INT;
    DECLARE v_program_id INT;
    DECLARE v_action_by_user_id VARCHAR(200);

    -- Look up program_id from program name
    SELECT program_id INTO v_program_id
    FROM tbl_program
    WHERE name = p_program_name
    LIMIT 1;

    IF v_program_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Program not found';
    END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id
    FROM tbl_user
    WHERE email = p_action_by_email
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Get user_id of executive member
    SELECT user_id INTO v_user_id
    FROM tbl_user
    WHERE email = p_email
    LIMIT 1;

    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Executive member not found';
    END IF;

    -- Get role_id for 'Student'
    SELECT role_id INTO v_role_id
    FROM tbl_role
    WHERE LOWER(role_name) = 'student'
    LIMIT 1;

    -- Get rank_id from the specified rank level
    SELECT rank_id INTO v_rank_id
    FROM tbl_executive_rank
    WHERE rank_level = p_rank_level
    LIMIT 1;

    IF v_rank_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid rank level';
    END IF;

    -- Update user program and role if needed
    UPDATE tbl_user
    SET program_id = v_program_id, role_id = v_role_id
    WHERE user_id = v_user_id;

    -- Update executive role or create if not exists
    SELECT executive_role_id INTO v_executive_role_id
    FROM tbl_executive_role
    WHERE organization_id = p_organization_id
      AND cycle_number = p_cycle_number
      AND role_title = p_role_title
      AND rank_id = v_rank_id
    LIMIT 1;

    IF v_executive_role_id IS NULL THEN
        INSERT INTO tbl_executive_role (
            organization_id,
            cycle_number,
            role_title,
            rank_id,
            created_at
        ) VALUES (
            p_organization_id,
            p_cycle_number,
            p_role_title,
            v_rank_id,
            CURRENT_TIMESTAMP
        );
        SET v_executive_role_id = LAST_INSERT_ID();
    END IF;

    -- Update organization member's executive role
    UPDATE tbl_organization_members
    SET executive_role_id = v_executive_role_id
    WHERE organization_id = p_organization_id
      AND cycle_number = p_cycle_number
      AND user_id = v_user_id
      AND member_type = 'Executive';

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Updated executive member: ', v_user_id, ' (', p_email, ') as ', p_role_title),
        'executive_member_update',
        JSON_OBJECT(
            'organization_id', p_organization_id,
            'cycle_number', p_cycle_number,
            'user_id', v_user_id,
            'executive_role_id', v_executive_role_id,
            'role_title', p_role_title,
            'rank_level', p_rank_level,
            'program_id', v_program_id
        ),
        CURRENT_TIMESTAMP
    );
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ArchiveExecutiveMember(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_email VARCHAR(100),
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_member_id INT;
    DECLARE v_executive_role_id INT;
    DECLARE v_archived_by VARCHAR(200);

    -- Get user_id of executive member
    SELECT user_id INTO v_user_id
    FROM tbl_user
    WHERE email = p_email
    LIMIT 1;

    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Executive member not found';
    END IF;

    -- Get member_id and executive_role_id
    SELECT member_id, executive_role_id INTO v_member_id, v_executive_role_id
    FROM tbl_organization_members
    WHERE organization_id = p_organization_id
      AND cycle_number = p_cycle_number
      AND user_id = v_user_id
      AND member_type = 'Executive'
    LIMIT 1;

    IF v_member_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Executive membership not found';
    END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_archived_by
    FROM tbl_user
    WHERE email = p_action_by_email
    LIMIT 1;

    IF v_archived_by IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Archive the executive member
    INSERT INTO tbl_archived_organization_members (
        member_id,
        organization_id,
        cycle_number,
        user_id,
        member_type,
        executive_role_id,
        archived_by
    ) VALUES (
        v_member_id,
        p_organization_id,
        p_cycle_number,
        v_user_id,
        'Executive',
        v_executive_role_id,
        v_archived_by
    );

    -- Remove from active members
    DELETE FROM tbl_organization_members
    WHERE member_id = v_member_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_archived_by,
        CONCAT('Archived executive member: ', v_user_id, ' (', p_email, ') from org ', p_organization_id),
        'executive_member_archive',
        JSON_OBJECT(
            'organization_id', p_organization_id,
            'cycle_number', p_cycle_number,
            'user_id', v_user_id,
            'member_id', v_member_id,
            'executive_role_id', v_executive_role_id
        ),
        CURRENT_TIMESTAMP
    );
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetAllPrograms()
BEGIN
    SELECT * FROM tbl_program;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetOrganizationCommittees(
    IN p_organization_id INT,
    IN p_cycle_number INT)
BEGIN
    -- Validate organization exists
    IF NOT EXISTS (
        SELECT 1 FROM tbl_organization 
        WHERE organization_id = p_organization_id
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization not found';
    END IF;

    -- Validate cycle exists
    IF NOT EXISTS (
        SELECT 1 FROM tbl_renewal_cycle 
        WHERE organization_id = p_organization_id 
        AND cycle_number = p_cycle_number
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Renewal cycle not found';
    END IF;

    -- Get all committees with member counts
    SELECT 
        c.committee_id,
        c.name AS committee_name,
        c.description,
        c.created_at,
        COUNT(cm.user_id) AS member_count,
        (SELECT COUNT(*) FROM tbl_committee_members 
         WHERE committee_id = c.committee_id AND role = 'Committee Head') AS head_count
    FROM tbl_committee c
    LEFT JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
    WHERE c.organization_id = p_organization_id
    AND c.cycle_number = p_cycle_number
    GROUP BY c.committee_id, c.name, c.description, c.created_at
    ORDER BY c.name;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE CreateCommittee(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_committee_name VARCHAR(100),
    IN p_description TEXT,
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_organization_exists INT;
    DECLARE v_cycle_exists INT;
    DECLARE v_committee_exists INT;
    DECLARE v_new_committee_id INT;

    -- Validate organization exists and is active
    SELECT COUNT(*) INTO v_organization_exists 
    FROM tbl_organization 
    WHERE organization_id = p_organization_id 
    AND status IN ('Approved', 'Renewal');
    
    IF v_organization_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Organization not found or not active';
    END IF;

    -- Validate renewal cycle exists
    SELECT COUNT(*) INTO v_cycle_exists 
    FROM tbl_renewal_cycle 
    WHERE organization_id = p_organization_id 
    AND cycle_number = p_cycle_number;
    
    IF v_cycle_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Renewal cycle not found';
    END IF;

    -- Check if committee already exists for this org/cycle
    SELECT COUNT(*) INTO v_committee_exists
    FROM tbl_committee
    WHERE organization_id = p_organization_id
    AND cycle_number = p_cycle_number
    AND name = p_committee_name;
    
    IF v_committee_exists > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Committee with this name already exists';
    END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id 
    FROM tbl_user 
    WHERE email = p_action_by_email 
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Create the committee
    INSERT INTO tbl_committee (
        organization_id,
        cycle_number,
        name,
        description,
        created_at
    ) VALUES (
        p_organization_id,
        p_cycle_number,
        p_committee_name,
        p_description,
        CURRENT_TIMESTAMP
    );
    
    SET v_new_committee_id = LAST_INSERT_ID();

    -- Log the action
    INSERT INTO tbl_logs (
        user_id, 
        action, 
        type, 
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Created committee: ', p_committee_name),
        'committee_creation',
        JSON_OBJECT(
            'organization_id', p_organization_id,
            'cycle_number', p_cycle_number,
            'committee_id', v_new_committee_id,
            'committee_name', p_committee_name
        ),
        CURRENT_TIMESTAMP
    );
    
    -- Return the new committee ID
    SELECT v_new_committee_id AS committee_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE UpdateCommittee(
    IN p_committee_id INT,
    IN p_new_name VARCHAR(100),
    IN p_new_description TEXT,
    IN p_action_by_email VARCHAR(100))
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_committee_exists INT;
    DECLARE v_organization_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_current_name VARCHAR(100);
    DECLARE v_current_description TEXT;

    -- Check if committee exists and get current values
   SELECT  
        organization_id, 
        cycle_number, 
        name,
        description
    INTO 
        v_organization_id, 
        v_cycle_number,
        v_current_name,
        v_current_description
    FROM tbl_committee
    WHERE committee_id = p_committee_id;

    IF v_organization_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Committee not found';
    END IF;

    -- Check if new name already exists for this org/cycle
    IF p_new_name IS NOT NULL AND p_new_name <> v_current_name THEN
        SELECT COUNT(*) INTO v_committee_exists
        FROM tbl_committee
        WHERE organization_id = v_organization_id
        AND cycle_number = v_cycle_number
        AND name = p_new_name;
        
        IF v_committee_exists > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Committee with this name already exists';
        END IF;
    END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id 
    FROM tbl_user 
    WHERE email = p_action_by_email 
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Update the committee
    UPDATE tbl_committee
    SET 
        name = COALESCE(p_new_name, name),
        description = COALESCE(p_new_description, description)
    WHERE committee_id = p_committee_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id, 
        action, 
        type, 
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Updated committee: ', v_current_name, 
               CASE WHEN p_new_name IS NOT NULL AND p_new_name <> v_current_name 
                    THEN CONCAT(' to ', p_new_name) 
                    ELSE '' END),
        'committee_update',
        JSON_OBJECT(
            'committee_id', p_committee_id,
            'old_name', v_current_name,
            'new_name', COALESCE(p_new_name, v_current_name),
            'old_description', v_current_description,
            'new_description', COALESCE(p_new_description, v_current_description),
            'organization_id', v_organization_id,
            'cycle_number', v_cycle_number
        ),
        CURRENT_TIMESTAMP
    );
    
    SELECT ROW_COUNT() AS rows_affected;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ArchiveCommittee(
    IN p_committee_id INT,
    IN p_reason VARCHAR(255),
    IN p_archived_by_email VARCHAR(100))
BEGIN
    DECLARE v_archived_by_id VARCHAR(200);
    DECLARE v_committee_exists INT;
    DECLARE v_organization_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_committee_name VARCHAR(100);
    DECLARE v_committee_description TEXT;
    DECLARE v_created_at TIMESTAMP;
    DECLARE v_member_count INT;

    -- Check if committee exists
    SELECT organization_id, cycle_number, name, description, created_at
    INTO v_organization_id, v_cycle_number, v_committee_name, v_committee_description, v_created_at
    FROM tbl_committee
    WHERE committee_id = p_committee_id;

    IF v_organization_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Committee not found';
    END IF;

    -- Get user_id of the archiver
    SELECT user_id INTO v_archived_by_id 
    FROM tbl_user 
    WHERE email = p_archived_by_email 
    LIMIT 1;

    IF v_archived_by_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Archiving user not found';
    END IF;

    -- Count members in this committee
    SELECT COUNT(*) INTO v_member_count
    FROM tbl_committee_members
    WHERE committee_id = p_committee_id;

    -- Start transaction
    START TRANSACTION;

    -- 1. Archive the committee FIRST
    INSERT INTO tbl_archived_committees (
        original_committee_id,
        organization_id,
        cycle_number,
        name,
        description,
        created_at,
        archived_at,
        archived_by,
        reason
    ) VALUES (
        p_committee_id,
        v_organization_id,
        v_cycle_number,
        v_committee_name,
        v_committee_description,
        v_created_at,
        CURRENT_TIMESTAMP,
        v_archived_by_id,
        p_reason
    );

    -- 2. Archive committee members (now committee_id is valid in archived_committees)
    INSERT INTO tbl_archived_organization_members (
        member_id,
        organization_id,
        cycle_number,
        user_id,
        member_type,
        committee_id,
        committee_role,
        archived_at,
        archived_by
    )
    SELECT 
        cm.committee_member_id,
        v_organization_id,
        v_cycle_number,
        cm.user_id,
        'Committee',
        p_committee_id,
        cm.role,
        CURRENT_TIMESTAMP,
        v_archived_by_id
    FROM tbl_committee_members cm
    WHERE cm.committee_id = p_committee_id;

    -- 3. Delete committee members
    DELETE FROM tbl_committee_members WHERE committee_id = p_committee_id;

    -- 4. Delete committee roles and permissions
    DELETE crp FROM tbl_committee_role_permission crp
    JOIN tbl_committee_role cr ON crp.committee_role_id = cr.committee_role_id
    WHERE cr.committee_id = p_committee_id;

    -- 5. Delete committee roles
    DELETE FROM tbl_committee_role WHERE committee_id = p_committee_id;

    -- 6. Finally, delete the committee
    DELETE FROM tbl_committee WHERE committee_id = p_committee_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id, 
        action, 
        type, 
        meta_data,
        timestamp
    ) VALUES (
        v_archived_by_id,
        CONCAT('Archived committee: ', v_committee_name, ' (', v_member_count, ' members)'),
        'committee_archive',
        JSON_OBJECT(
            'original_committee_id', p_committee_id,
            'committee_name', v_committee_name,
            'organization_id', v_organization_id,
            'cycle_number', v_cycle_number,
            'member_count', v_member_count,
            'reason', p_reason
        ),
        CURRENT_TIMESTAMP
    );

    COMMIT;
    
    SELECT ROW_COUNT() AS committees_archived;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetAllCommitteeMembers()
BEGIN
    -- Return all committees with their members
    SELECT 
        c.committee_id,
        c.name AS committee_name,
        c.description,
        c.organization_id,
        c.cycle_number,
        cm.committee_member_id,
        cm.role,
        cm.created_at AS member_since,
        u.user_id,
        u.f_name,
        u.l_name,
        u.email,
        u.profile_picture,
        p.name AS program_name,
        u.status AS user_status
    FROM tbl_committee c
    LEFT JOIN tbl_committee_members cm ON c.committee_id = cm.committee_id
    LEFT JOIN tbl_user u ON cm.user_id = u.user_id
    LEFT JOIN tbl_program p ON u.program_id = p.program_id
    ORDER BY 
        c.organization_id,
        c.cycle_number,
        c.name,
        CASE WHEN cm.role = 'Committee Head' THEN 0 ELSE 1 END,
        u.l_name, u.f_name;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddCommitteeMember(
    IN p_committee_id INT,
    IN p_user_email VARCHAR(100),
    IN p_role ENUM('Committee Head', 'Committee Officer'),
    IN p_action_by_email VARCHAR(100))
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_committee_exists INT;
    DECLARE v_organization_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_is_member INT;
    DECLARE v_new_member_id INT;

    -- Check if committee exists
    SELECT organization_id, cycle_number 
        INTO v_organization_id, v_cycle_number
        FROM tbl_committee
        WHERE committee_id = p_committee_id;

        IF v_organization_id IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Committee not found';
        END IF;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id 
    FROM tbl_user 
    WHERE email = p_action_by_email 
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

        -- Get user_id of the member to add
    SELECT user_id INTO v_user_id 
    FROM tbl_user 
    WHERE email = p_user_email 
    LIMIT 1;

    IF v_user_id IS NULL THEN
        -- Insert new user with pending status
        SET v_user_id = CONCAT('usr-', UUID_SHORT());
        INSERT INTO tbl_user (
            user_id,
            email,
            role_id,
            status,
            created_at,
            updated_at
        ) VALUES (
            v_user_id,
            p_user_email,
            (SELECT role_id FROM tbl_role WHERE LOWER(role_name) = 'student' LIMIT 1),
            'Pending',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    -- Check if user is already in this committee
    SELECT COUNT(*) INTO v_is_member
    FROM tbl_committee_members
    WHERE committee_id = p_committee_id
    AND user_id = v_user_id;
    
    IF v_is_member > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'User is already a member of this committee';
    END IF;

    -- Add the committee member
    INSERT INTO tbl_committee_members (
        committee_id,
        user_id,
        role,
        created_at
    ) VALUES (
        p_committee_id,
        v_user_id,
        p_role,
        CURRENT_TIMESTAMP
    );
    
    SET v_new_member_id = LAST_INSERT_ID();

    -- Log the action
    INSERT INTO tbl_logs (
        user_id, 
        action, 
        type, 
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Added member to committee: ', 
               (SELECT name FROM tbl_committee WHERE committee_id = p_committee_id)),
        'committee_member_add',
        JSON_OBJECT(
            'committee_id', p_committee_id,
            'user_id', v_user_id,
            'role', p_role,
            'organization_id', v_organization_id,
            'cycle_number', v_cycle_number
        ),
        CURRENT_TIMESTAMP
    );
    
    SELECT v_new_member_id AS committee_member_id;
END$$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE ScanTicket(
    IN p_email VARCHAR(100),
    IN p_event_title VARCHAR(300),
    IN p_verifier_user_id VARCHAR(200)  -- New parameter for verifier
)
BEGIN
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_event_id INT;
    DECLARE v_organization_id INT;
    DECLARE v_attendance_id INT;
    DECLARE v_is_authorized BOOLEAN DEFAULT FALSE;
    
    -- Get user ID from email
    SELECT user_id INTO v_user_id
    FROM tbl_user
    WHERE email = p_email;
    
    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found with the provided email';
    END IF;
    
    -- Get event ID and organization from title
    SELECT event_id, organization_id INTO v_event_id, v_organization_id
    FROM tbl_event
    WHERE title = p_event_title
    AND status = 'Approved';
    
    IF v_event_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Active event not found with the provided title';
    END IF;
    
    -- Verify scanning user's authority (Executive or Committee Head)
    SELECT EXISTS (
        SELECT 1
        FROM tbl_organization_members om
        JOIN tbl_renewal_cycle rc 
            ON om.organization_id = rc.organization_id 
            AND om.cycle_number = rc.cycle_number
        WHERE om.organization_id = v_organization_id
        AND om.user_id = p_verifier_user_id
        AND om.status = 'Active'
        AND (
            om.member_type = 'Executive'  -- Executive members
            OR (
                om.member_type = 'Committee'  -- Committee Heads
                AND EXISTS (
                    SELECT 1
                    FROM tbl_committee_members cm
                    JOIN tbl_committee c ON cm.committee_id = c.committee_id
                    WHERE cm.user_id = p_verifier_user_id
                    AND c.organization_id = v_organization_id
                    AND cm.role = 'Committee Head'
                )
            )
        )
    ) INTO v_is_authorized;
    
    IF NOT v_is_authorized THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not authorized to verify tickets for this event';
    END IF;
    
    -- Find existing attendance record
    SELECT attendance_id INTO v_attendance_id
    FROM tbl_event_attendance
    WHERE event_id = v_event_id
    AND user_id = v_user_id
    AND status IN ('Registered')  -- Only allow scan for these statuses
    AND deleted_at IS NULL;  -- Not deleted
    
    IF v_attendance_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No valid registration found for this user and event';
    END IF;
    
    -- Update attendance record
    UPDATE tbl_event_attendance
    SET 
        status = 'Attended',
        time_in = NOW()
    WHERE attendance_id = v_attendance_id;
    
    -- Return success message
    SELECT 'Ticket scanned successfully' AS message;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE AddEventRequirement(
    IN p_requirement_name VARCHAR(255),
    IN p_requirement_type ENUM('pre-event', 'post-event'),
    IN p_savePath VARCHAR(255),  -- Can be NULL
    IN p_created_by VARCHAR(200)
)
BEGIN
    DECLARE v_user_exists INT;

    -- Validate requirement name
    IF TRIM(p_requirement_name) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Requirement name cannot be empty';
    END IF;

    -- Check if creating user exists
    SELECT COUNT(*) INTO v_user_exists
    FROM tbl_user
    WHERE user_id = p_created_by;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Creating user does not exist';
    END IF;

    -- Insert the new requirement
    INSERT INTO tbl_event_application_requirement (
        requirement_name,
        is_applicable_to,
        file_path,
        created_by
    ) VALUES (
        p_requirement_name,
        p_requirement_type,
        NULLIF(p_savePath, ''),  -- Convert empty string to NULL
        p_created_by
    );
    
    -- Return success message with new ID
    SELECT CONCAT('Requirement added successfully. ID: ', LAST_INSERT_ID()) AS message;
END$$

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE UpdateCommitteeMember(
    IN p_committee_member_id INT,
    IN p_new_role ENUM('Committee Head', 'Committee Officer'),
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_committee_id INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_old_role ENUM('Committee Head', 'Committee Officer');

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id
    FROM tbl_user
    WHERE email = p_action_by_email
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Get current member info
    SELECT committee_id, user_id, role INTO v_committee_id, v_user_id, v_old_role
    FROM tbl_committee_members
    WHERE committee_member_id = p_committee_member_id;

    IF v_committee_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Committee member not found';
    END IF;

    -- Update the role
    UPDATE tbl_committee_members
    SET role = p_new_role
    WHERE committee_member_id = p_committee_member_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Updated committee member role: ', v_user_id, ' in committee ', v_committee_id, ' from ', v_old_role, ' to ', p_new_role),
        'committee_member_update',
        JSON_OBJECT(
            'committee_member_id', p_committee_member_id,
            'committee_id', v_committee_id,
            'user_id', v_user_id,
            'old_role', v_old_role,
            'new_role', p_new_role
        ),
        CURRENT_TIMESTAMP
    );

    SELECT ROW_COUNT() AS rows_affected;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ArchiveCommitteeMember(
    IN p_committee_member_id INT,
    IN p_reason VARCHAR(255),
    IN p_action_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_committee_id INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_role ENUM('Committee Head', 'Committee Officer');
    DECLARE v_organization_id INT;
    DECLARE v_cycle_number INT;

    -- Get user_id of the action performer
    SELECT user_id INTO v_action_by_user_id
    FROM tbl_user
    WHERE email = p_action_by_email
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Get current member info
    SELECT cm.committee_id, cm.user_id, cm.role, c.organization_id, c.cycle_number
    INTO v_committee_id, v_user_id, v_role, v_organization_id, v_cycle_number
    FROM tbl_committee_members cm
    JOIN tbl_committee c ON cm.committee_id = c.committee_id
    WHERE cm.committee_member_id = p_committee_member_id;

    IF v_committee_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Committee member not found';
    END IF;

    -- Archive the member
    INSERT INTO tbl_archived_organization_members (
        member_id,
        organization_id,
        cycle_number,
        user_id,
        member_type,
        committee_id,
        committee_role,
        archived_at,
        archived_by
    ) VALUES (
        p_committee_member_id,
        v_organization_id,
        v_cycle_number,
        v_user_id,
        'Committee',
        v_committee_id,
        v_role,
        CURRENT_TIMESTAMP,
        v_action_by_user_id
    );

    -- Remove from active members
    DELETE FROM tbl_committee_members
    WHERE committee_member_id = p_committee_member_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Archived committee member: ', v_user_id, ' from committee ', v_committee_id),
        'committee_member_archive',
        JSON_OBJECT(
            'committee_member_id', p_committee_member_id,
            'committee_id', v_committee_id,
            'user_id', v_user_id,
            'role', v_role,
            'organization_id', v_organization_id,
            'cycle_number', v_cycle_number,
            'reason', p_reason
        ),
        CURRENT_TIMESTAMP
    );

    SELECT ROW_COUNT() AS rows_archived;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE GetPendingOrganizationMembers(
    IN p_organization_id INT,
    IN p_cycle_number INT
)
BEGIN
    SELECT
        om.member_id,
        om.organization_id,
        om.cycle_number,
        om.user_id,
        u.f_name,
        u.l_name,
        u.email,
        u.profile_picture,
        om.member_type,
        om.status,
        ma.application_id,
        ma.status AS application_status,
        ma.applied_at,
        ma.reviewed_by,
        ma.reviewed_at,
        org.membership_fee_type,
        org.membership_fee_amount,
        t.transaction_id,
        t.amount AS paid_amount,
        t.status AS payment_status,
        t.proof_image
    FROM tbl_organization_members om
    JOIN tbl_user u ON om.user_id = u.user_id
    LEFT JOIN tbl_membership_application ma
        ON om.organization_id = ma.organization_id
        AND om.cycle_number = ma.cycle_number
        AND om.user_id = ma.user_id
    LEFT JOIN tbl_organization org ON om.organization_id = org.organization_id
    LEFT JOIN tbl_transaction_membership tm
        ON tm.organization_id = om.organization_id
        AND tm.cycle_number = om.cycle_number
    LEFT JOIN tbl_transaction t
        ON tm.transaction_id = t.transaction_id
        AND t.user_id = om.user_id
        AND t.transaction_type = 'Membership Fee'
    WHERE om.organization_id = p_organization_id
      AND om.cycle_number = p_cycle_number
      AND om.status = 'Pending'
    ORDER BY om.joined_at DESC;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER='admin'@'%' PROCEDURE ApproveMembershipApplication(
    IN p_application_id INT,
    IN p_reviewer_email VARCHAR(200),
    IN p_remarks TEXT
)
BEGIN
    DECLARE v_org_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_reviewer_id VARCHAR(200);

    -- Get application details
    SELECT organization_id, cycle_number, user_id
      INTO v_org_id, v_cycle_number, v_user_id
      FROM tbl_membership_application
     WHERE application_id = p_application_id;

    -- Get reviewer user_id from email
    SELECT user_id INTO v_reviewer_id
      FROM tbl_user
     WHERE email = p_reviewer_email
     LIMIT 1;

    -- Approve application
    UPDATE tbl_membership_application
       SET status = 'Approved',
           reviewed_by = v_reviewer_id,
           reviewed_at = NOW(),
           remarks = p_remarks
     WHERE application_id = p_application_id;

    -- Update member status
    UPDATE tbl_organization_members
       SET status = 'Active'
     WHERE organization_id = v_org_id
       AND cycle_number = v_cycle_number
       AND user_id = v_user_id;

    -- Log the approval
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_reviewer_id,
        CONCAT('Approved membership application ID: ', p_application_id),
        'membership_application_approval',
        JSON_OBJECT(
            'application_id', p_application_id,
            'organization_id', v_org_id,
            'cycle_number', v_cycle_number,
            'member_user_id', v_user_id,
            'remarks', p_remarks
        ),
        NOW()
    );
END$$
DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE RejectMembershipApplication(
    IN p_application_id INT,
    IN p_reviewer_email VARCHAR(200),
    IN p_remarks TEXT
)
BEGIN
    DECLARE v_org_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_reviewer_id VARCHAR(200);

    -- Get application details
    SELECT organization_id, cycle_number, user_id
      INTO v_org_id, v_cycle_number, v_user_id
      FROM tbl_membership_application
     WHERE application_id = p_application_id;

    -- Get reviewer user_id from email
    SELECT user_id INTO v_reviewer_id
      FROM tbl_user
     WHERE email = p_reviewer_email
     LIMIT 1;

    -- Reject application
    UPDATE tbl_membership_application
       SET status = 'Rejected',
           reviewed_by = v_reviewer_id,
           reviewed_at = NOW(),
           remarks = p_remarks
     WHERE application_id = p_application_id;

    -- Only archive if member is still pending
    UPDATE tbl_organization_members
       SET status = 'Archived'
     WHERE organization_id = v_org_id
       AND cycle_number = v_cycle_number
       AND user_id = v_user_id
       AND status = 'Pending';

    -- Log the rejection
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_reviewer_id,
        CONCAT('Rejected membership application ID: ', p_application_id),
        'membership_application_rejection',
        JSON_OBJECT(
            'application_id', p_application_id,
            'organization_id', v_org_id,
            'cycle_number', v_cycle_number,
            'member_user_id', v_user_id,
            'remarks', p_remarks
        ),
        NOW()
    );
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE AddOrganizationMember(
    IN p_organization_id INT,
    IN p_cycle_number INT,
    IN p_email VARCHAR(100),
    IN p_status VARCHAR(20),
    IN p_executive_role_id INT,
    IN p_action_by_email VARCHAR(100),
    IN p_program_name VARCHAR(50)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_action_by_user_id VARCHAR(200);
    DECLARE v_program_id INT DEFAULT NULL;
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_user_id VARCHAR(200);

    -- Get the user_id of the action performer
    SELECT user_id INTO v_action_by_user_id
    FROM tbl_user
    WHERE email = p_action_by_email
    LIMIT 1;

    IF v_action_by_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action performer not found';
    END IF;

    -- Check if user exists by email
    SELECT user_id INTO v_user_id FROM tbl_user WHERE email = p_email LIMIT 1;
    SET v_user_exists = IFNULL(v_user_id IS NOT NULL, 0);

    -- If program_name is provided, look up its id
    IF p_program_name IS NOT NULL AND p_program_name != '' THEN
        SELECT program_id INTO v_program_id
        FROM tbl_program
        WHERE name = p_program_name
        LIMIT 1;

        IF v_program_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Program name not found';
        END IF;
    END IF;

    -- If user does not exist, create a pending user with generated user_id
    IF v_user_exists = 0 THEN
        SET v_user_id = CONCAT('usr-', UUID_SHORT());
        INSERT INTO tbl_user (
            user_id,
            email,
            role_id,
            program_id,
            status
        ) VALUES (
            v_user_id,
            p_email,
            (SELECT role_id FROM tbl_role WHERE LOWER(role_name) = 'student' LIMIT 1),
            v_program_id,
            'Pending'
        );
    END IF;

    -- Check if renewal cycle exists
    IF NOT EXISTS (
        SELECT 1 FROM tbl_renewal_cycle WHERE organization_id = p_organization_id AND cycle_number = p_cycle_number
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Renewal cycle does not exist';
    END IF;

    -- Prevent duplicate membership
    SELECT COUNT(*) INTO v_exists
    FROM tbl_organization_members
    WHERE organization_id = p_organization_id
      AND cycle_number = p_cycle_number
      AND user_id = v_user_id;

    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User is already a member of this organization and cycle';
    END IF;

    -- If program_name is provided, update user's program_id
    IF v_program_id IS NOT NULL THEN
        UPDATE tbl_user
        SET program_id = v_program_id
        WHERE user_id = v_user_id;
    END IF;

    -- Insert member (default member_type is 'Member')
    INSERT INTO tbl_organization_members (
        organization_id,
        cycle_number,
        user_id,
        member_type,
        status,
        executive_role_id
    ) VALUES (
        p_organization_id,
        p_cycle_number,
        v_user_id,
        'Member',
        p_status,
        p_executive_role_id
    );

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_action_by_user_id,
        CONCAT('Added organization member: ', v_user_id, ' to org ', p_organization_id, ' cycle ', p_cycle_number),
        'organization_member_add',
        JSON_OBJECT(
            'organization_id', p_organization_id,
            'cycle_number', p_cycle_number,
            'user_id', v_user_id,
            'email', p_email,
            'member_type', 'Member',
            'status', p_status,
            'executive_role_id', p_executive_role_id,
            'program_id', v_program_id,
            'program_name', p_program_name
        ),
        NOW()
    );
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE EditOrganizationMember(
    IN p_current_email VARCHAR(100),
    IN p_new_email VARCHAR(100),
    IN p_new_program_name VARCHAR(50)
)
BEGIN
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_program_id INT;

    -- Get user_id from the current email
    SELECT user_id INTO v_user_id
    FROM tbl_user
    WHERE email = p_current_email
    LIMIT 1;

    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found';
    END IF;

    -- Look up program_id from program name
    IF p_new_program_name IS NOT NULL AND p_new_program_name != '' THEN
        SELECT program_id INTO v_program_id
        FROM tbl_program
        WHERE name = p_new_program_name
        LIMIT 1;

        IF v_program_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Program name not found';
        END IF;
    ELSE
        SET v_program_id = NULL;
    END IF;

    -- Update user's email and program_id
    UPDATE tbl_user
    SET email = p_new_email,
        program_id = v_program_id
    WHERE user_id = v_user_id;
END$$

DELIMITER ;

DELIMITER $$

CREATE DEFINER='admin'@'%' PROCEDURE ArchiveOrganizationMember(
    IN p_member_id INT,
    IN p_archived_by_email VARCHAR(100)
)
BEGIN
    DECLARE v_archived_by VARCHAR(200);
    DECLARE v_organization_id INT;
    DECLARE v_cycle_number INT;
    DECLARE v_user_id VARCHAR(200);
    DECLARE v_member_type ENUM('Member', 'Executive', 'Committee');
    DECLARE v_executive_role_id INT;
    DECLARE v_committee_id INT;
    DECLARE v_committee_role ENUM('Committee Head', 'Committee Officer');

    -- Get user_id of the archiver
    SELECT user_id INTO v_archived_by
    FROM tbl_user
    WHERE email = p_archived_by_email
    LIMIT 1;

    IF v_archived_by IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Archiving user not found';
    END IF;

    -- Get member details
    SELECT 
        om.organization_id,
        om.cycle_number,
        om.user_id,
        om.member_type,
        om.executive_role_id,
        NULL, -- committee_id (not tracked in tbl_organization_members)
        NULL  -- committee_role (not tracked in tbl_organization_members)
    INTO
        v_organization_id,
        v_cycle_number,
        v_user_id,
        v_member_type,
        v_executive_role_id,
        v_committee_id,
        v_committee_role
    FROM tbl_organization_members om
    WHERE om.member_id = p_member_id;

    IF v_organization_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Organization member not found';
    END IF;

    -- Archive the member
    INSERT INTO tbl_archived_organization_members (
        member_id,
        organization_id,
        cycle_number,
        user_id,
        member_type,
        executive_role_id,
        committee_id,
        committee_role,
        archived_at,
        archived_by
    ) VALUES (
        p_member_id,
        v_organization_id,
        v_cycle_number,
        v_user_id,
        v_member_type,
        v_executive_role_id,
        v_committee_id,
        v_committee_role,
        CURRENT_TIMESTAMP,
        v_archived_by
    );

    -- Remove from active members
    DELETE FROM tbl_organization_members
    WHERE member_id = p_member_id;

    -- Log the action
    INSERT INTO tbl_logs (
        user_id,
        action,
        type,
        meta_data,
        timestamp
    ) VALUES (
        v_archived_by,
        CONCAT('Archived organization member: ', v_user_id, ' (member_id ', p_member_id, ') from org ', v_organization_id),
        'organization_member_archive',
        JSON_OBJECT(
            'member_id', p_member_id,
            'organization_id', v_organization_id,
            'cycle_number', v_cycle_number,
            'user_id', v_user_id,
            'member_type', v_member_type,
            'executive_role_id', v_executive_role_id
        ),
        CURRENT_TIMESTAMP
    );
END$$

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
("VIEW_APPLICATION"),
("MANAGE_APPLICATIONS"),
("CREATE_EVALUATION"),
("UPDATE_EVALUATION"),
("DELETE_EVALUATION"),
("VIEW_EVALUATION"),
("VIEW_LOGS"),
("WEB_ACCESS"),
("MANAGE_REGISTRATION"),
("SUBMIT_REQUIREMENTS");

INSERT INTO tbl_role_permission (role_id, permission_id) 
VALUES
(4,1),
(4,2),
(4,3),
(4,4),
(4,8),
(4,9),
(4,10),
(4,11),
(4,12),
(4,13),
(4,14),
(4,15),
(4,17),
(4,19),
(4,21),
(4,22),
(4,23),
(4,24),
(4,25),
(2,6),
(2,9),
(2,17),
(2,23),
(3,17),
(4,17),
(5,17),
(6,17),
(3,23),
(5,23),
(6,23),
(3,9),
(5,9),
(6,9),
(3,16),
(5,16),
(6,16);


INSERT INTO tbl_program (name, description) VALUES 
("Bachelor of Science in Information Technology", "BSIT"),
("Bachelor of Science in Computer Science", "BSCS");

INSERT INTO tbl_user (user_id, f_name, l_name, email, program_id, role_id) VALUES
("6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0", "Benson","Javier","javierbb@students.nu-dasma.edu.ph",null,4);




INSERT INTO tbl_executive_rank (rank_level, default_title, description) VALUES
(1, 'President', 'Highest authority with full permissions'),
(2, 'Vice President', 'Second-in-command'),
(3, 'Secretary', 'Administrative lead'),
(4, 'Treasurer', 'Financial manager'),
(5, 'Officer', 'General executive member');

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


INSERT INTO tbl_rank_permission(rank_id, permission_id) VALUES
(1,9),
(1,16),
(1,11),
(1,12),
(1,13),
(1,14);
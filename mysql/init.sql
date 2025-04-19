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

CREATE TABLE tbl_program(
    program_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE tbl_user(
    user_id VARCHAR(200) UNIQUE NOT NULL PRIMARY KEY,
    f_name VARCHAR(50) NOT NULL,
    l_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    program_id INT NULL,
    role_id INT NOT NULL DEFAULT 1,
    profile_picture VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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

-- Organization Table

CREATE TABLE tbl_organization(
    organization_id INT AUTO_INCREMENT PRIMARY KEY,
    adviser_id VARCHAR(200) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    base_program_id INT NULL, -- NULL meaning open to all
    logo VARCHAR(255),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    approve_status INT, 
    membership_fee_type ENUM('Per Term', 'Whole Academic Year') NOT NULL,
    category ENUM('Academic', 'Non-Academic') DEFAULT 'Academic',
    membership_fee_amount DECIMAL(10,2) NOT NULL,
    is_recruiting BOOLEAN DEFAULT FALSE,
    is_open_to_all_courses BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adviser_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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

CREATE TABLE tbl_executive_role (
    executive_role_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    role_title VARCHAR(100) NOT NULL,  -- e.g., 'President', 'Vice-President'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_executive_role_permission (
    executive_role_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    executive_role_id INT NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (executive_role_id) REFERENCES tbl_executive_role(executive_role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_organization_members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    member_type ENUM('Member', 'Executive', 'Committee') DEFAULT 'Member',
    executive_role_id INT DEFAULT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (executive_role_id) REFERENCES tbl_executive_role (executive_role_id) ON DELETE SET NULL
);

CREATE TABLE tbl_executive_member_permission (
    executive_permission_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,  -- references tbl_organization_members
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES tbl_organization_members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES tbl_permission(permission_id) ON DELETE CASCADE
);

CREATE TABLE tbl_committee (
    committee_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
);

CREATE TABLE tbl_committee_members(
    committee_member_id INT AUTO_INCREMENT PRIMARY KEY,
    committee_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    role ENUM('Committee Head', 'Committee Officer') DEFAULT 'Committee Officer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES tbl_committee(committee_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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

CREATE TABLE tbl_organization_course(
	organization_id INT NOT NULL,
    program_id INT NOT NULL,
    PRIMARY KEY (organization_id,program_id),
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES tbl_program(program_id) ON DELETE CASCADE	
);

CREATE TABLE tbl_organization_requirements(
    requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE
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

CREATE TABLE tbl_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id VARCHAR(200) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT NOT NULL,
    venue VARCHAR(200) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', "Archived") DEFAULT 'Pending',
    type ENUM("Paid","Free"),
    date DATE NOT NULL,
    is_open_to_all BOOLEAN DEFAULT FALSE,
    fee INT NULL,
    capacity INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    certificate VARCHAR(1000) DEFAULT NULL,
    FOREIGN KEY (organization_id) REFERENCES tbl_organization(organization_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
);

CREATE TABLE tbl_certificate_template (
    template_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL UNIQUE, 
    template_path VARCHAR(255) NOT NULL,
    uploaded_by VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES tbl_certificate_template(template_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_cert (event_id, user_id) -- One cert per user per event
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
		FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
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
    FOREIGN KEY (event_id) REFERENCES tbl_event(event_id),
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id)
);

CREATE TABLE tbl_evaluation_response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    evaluation_id INT NOT NULL,
    question_id INT NOT NULL,
    response_value TEXT NOT NULL, -- Stores JSON/text/numerical values
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (evaluation_id) REFERENCES tbl_evaluation(evaluation_id)
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

-- Notifications Table: Stores the core notification details
CREATE TABLE tbl_notification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id VARCHAR(200) DEFAULT NULL,  
    entity_type ENUM('event', 'approval', 'organization', 'transaction', 'general') NOT NULL,
    entity_id INT DEFAULT NULL,           -- ID of the associated entity (e.g., event_id or approval_id)
    title VARCHAR(255) NOT NULL,          -- A short title for the notification
    message TEXT NOT NULL,                -- Detailed message
    url VARCHAR(255) DEFAULT NULL,        -- Optional URL for a direct link to the related page
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification Recipients Table: Each recipient gets an individual row
CREATE TABLE tbl_notification_recipient (
    notification_recipient_id INT AUTO_INCREMENT PRIMARY KEY,
    notification_id INT NOT NULL,         -- Links to the notification
    recipient_type ENUM('user', 'organization', 'program') NOT NULL,
    recipient_id VARCHAR(200) NOT NULL,     -- For a 'user', this is the user's ID; for 'organization' or 'program', it's the respective ID
    is_read BOOLEAN DEFAULT FALSE,          -- Tracks if the recipient has read the notification
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notification_id) REFERENCES tbl_notification(notification_id) ON DELETE CASCADE
);

CREATE TABLE tbl_logs(
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(200) NOT NULL,
    action TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE
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
        e.date,
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
            WHEN TIMESTAMP(e.date, e.end_time) < CURRENT_TIMESTAMP THEN 'Ended'
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
            WHEN TIMESTAMP(e.date, e.end_time) < CURRENT_TIMESTAMP THEN 1 
            ELSE 0 
        END,
        e.date ASC,
        e.start_time ASC;
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
    p_user_id VARCHAR(200),
    p_title VARCHAR(300),
    p_description TEXT,
    p_venue VARCHAR(200),
    p_date DATE,
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
        start_time,
        end_time,
        status,
        type,
        date,
        is_open_to_all
    ) VALUES (
        p_organization_id,
        p_user_id,
        p_title,
        p_description,
        p_venue,
        p_start_time,
        p_end_time,
        p_status,
        p_type,
        p_date,
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
        e.date,
        e.start_time,
        e.venue,
        o.name AS organization_name,
        ea.status,
        ea.created_at AS registration_date
    FROM tbl_event_attendance ea
    INNER JOIN tbl_event e ON ea.event_id = e.event_id
    INNER JOIN tbl_organization o ON e.organization_id = o.organization_id
    WHERE (ea.user_id = p_user_id) AND (ea.status = "Registered" OR "Attended")
    ORDER BY e.date DESC, e.start_time DESC;
END $$
DELIMITER ;

DELIMITER $$
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
            FROM tbl_organization_members om 
            WHERE om.organization_id = o.organization_id
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
                'event_date', e.date,
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
            AND e.date >= CURDATE()
            ORDER BY e.date ASC
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
        e.date,
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
      AND e.date >= CURDATE()
      AND (
          e.is_open_to_all = TRUE
          OR uo.organization_id IS NOT NULL
      )
    ORDER BY e.date ASC, e.start_time ASC
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


CREATE INDEX idx_org_members_user ON tbl_organization_members(user_id);
CREATE INDEX idx_event_program ON tbl_event_course(program_id);

CREATE INDEX idx_org_members ON tbl_organization_members(organization_id, user_id);
CREATE INDEX idx_committee_org ON tbl_committee(organization_id);
CREATE INDEX idx_committee_members_user ON tbl_committee_members(user_id);
    
INSERT INTO tbl_role(role_name)
VALUES("STUDENT"), 
("ADVISER"),
("PROGRAMCHAIR"),
("SDAO"),
("DEAN");

INSERT INTO tbl_program (name, description) VALUES 
("Bachelor of Science in Information Technology", "BSIT"),
("Bachelor of Science in Computer Science", "BSCS");

INSERT INTO tbl_user (user_id, f_name, l_name, email, program_id, role_id) VALUES
("900f929ec408cb4d","Benz","Jav","benz@gmail.com", 1, 2), 
("900f929ec408cb4","Benson","Javier","benson09.javier@outlook.com", 1 , 1),
("86533891asdvf","Test","test","test@gmail.com", 1, 1),
("5fb95ed0a0d20daf","Geraldine","Aris","arisgeraldine@outlook.com", 1, 1);

INSERT INTO tbl_organization (adviser_id, name, description, base_program_id, status, approve_status, membership_fee_type, membership_fee_amount, is_recruiting, is_open_to_all_courses) VALUES
("900f929ec408cb4d", "Computer Society", "This is the computer society", 1, "Approved", 5, "Whole Academic Year", 500, 0, 0),
("900f929ec408cb4d", "Isite","This is Isite", 2, "Approved", 5, "Whole Academic Year", 500,0,0);

INSERT INTO tbl_executive_role(organization_id, role_title)VALUES
(2,"President");

INSERT INTO tbl_organization_members(organization_id,user_id, member_type, executive_role_id)
VALUES (1, "900f929ec408cb4", "Member",null),
(2, "86533891asdvf", "Executive",null),
(2, "5fb95ed0a0d20daf","Member",1);

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
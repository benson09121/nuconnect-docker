-- INSERT INTO tbl_organization (adviser_id, name, description, base_program_id, status, membership_fee_type, membership_fee_amount, is_recruiting, is_open_to_all_courses) VALUES
-- ("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Computer Society", "This is the computer society", 1, "Approved", "Whole Academic Year", 500, 0, 0),
-- ("LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA", "Isite","This is Isite", 2, "Approved", "Whole Academic Year", 500,0,0);

-- INSERT INTO tbl_event (
--   event_id,
--   organization_id,
--   user_id,
--   title,
--   description,
--   venue_type,
--   venue,
--   start_date,
--   end_date,
--   start_time,
--   end_time,
--   status,
--   type,
--   is_open_to,
--   fee,
--   capacity,
--   created_at,
--   certificate
-- ) VALUES
-- (1001, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Innovation Pitch Fest', 'A competition for pitching new ideas', 'Face to face', 'NU Hall A', '2025-06-10', '2025-06-10', '09:00:00', '15:00:00', 'Approved', 'Paid', 'Open to all', 50, 100, '2025-05-01 08:00:00', 'Participation Certificate'),

-- (1002, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Groove Jam 2025', 'Annual inter-school dance battle', 'Face to face', 'Open Grounds', '2025-07-20', '2025-07-20', '13:00:00', '19:00:00', 'Approved', 'Free', 'Open to all', 0, 300, '2025-05-05 10:30:00', 'Winner + Participation'),

-- (1003, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Hack-It-Out', '24-hour Hackathon for IT majors', 'Face to face', 'Tech Lab 101', '2025-08-05', '2025-08-05', '08:00:00', '08:00:00', 'Pending', 'Paid', 'Members only', 200, 60, '2025-05-12 15:45:00', 'Certificate + Swag'),

-- (1004, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'Earth Hour Rally', 'Tree planting and cleanup event', 'Face to face', 'Community Park', '2025-06-15', '2025-06-15', '06:30:00', '10:30:00', 'Approved', 'Free', 'Open to all', 0, 150, '2025-05-15 09:00:00', 'Eco Warrior Badge'),

-- (1005, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 'E-Sports Showdown', 'Inter-university e-sports competition', 'Face to face', 'Auditorium', '2025-07-01', '2025-07-01', '10:00:00', '18:00:00', 'Rejected', 'Paid', 'Open to all', 100, 500, '2025-05-10 13:15:00', 'Winner Certificate'),

-- (2001, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Tech Expo', 'Annual technology exposition', 'Face to face', 'NU Convention Center', '2023-03-10', '2023-03-10', '08:00:00', '17:00:00', 'Approved', 'Free', 'Open to all', 0, 500, '2023-02-01 09:00:00', 'Certificate of Participation'),

-- (2002, 2, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Coding Bootcamp', 'Intensive coding bootcamp for beginners', 'Face to face', 'Lab 202', '2023-04-15', '2023-04-17', '09:00:00', '16:00:00', 'Approved', 'Paid', 'Members only', 100, 50, '2023-03-10 10:00:00', 'Certificate of Completion'),

-- (2003, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', '2023 Summer Seminar', 'Seminar on emerging technologies', 'Online', 'Zoom', '2023-05-05', '2023-05-05', '10:00:00', '12:00:00', 'Approved', 'Free', 'NU Students only', 0, 200, '2023-04-20 11:00:00', 'E-Certificate');

-- INSERT INTO tbl_executive_role(organization_id, role_title)VALUES
-- (2,"President");

-- INSERT INTO tbl_organization_members(organization_id,user_id, member_type, executive_role_id)
-- VALUES (1, "900f929ec408cb4", "Member",null),
-- (2, "86533891asdvf", "Executive",null),
-- (2, "5fb95ed0a0d20daf","Member",1);

-- 



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

-- Insert 20 sample attendance records matching your users and events
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
(2003, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 'Pending', NULL, NULL),
(2003, '900f929ec408cb4', 'Attended', '2023-05-05 09:45:00', '2023-05-05 12:15:00');

-- Insert test event
INSERT INTO tbl_event (
  event_id, organization_id, user_id, title, 
  description, venue_type, venue, start_date, 
  end_date, start_time, end_time, status, 
  type, is_open_to, fee, capacity, created_at
) VALUES (
  9998, 1, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 
  'Tech Conference 2023', 'Annual technology conference', 
  'Face to face', 'NU Convention Center', '2023-11-15', 
  '2023-11-17', '08:00:00', '18:00:00', 
  'Approved', 'Paid', 'Open to all', 500, 200, NOW()
);

-- Attendee 1: Pending approval with transaction
INSERT INTO tbl_transaction (
  user_id, amount, transaction_type, status, proof_image, created_at
) VALUES (
  '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 
  500, 'Event Fee', 'Pending', 'payment_proof1.jpg', NOW()
);

INSERT INTO tbl_transaction_event (
  transaction_id, event_id, remarks
) VALUES (
  LAST_INSERT_ID(), 9998, 'Early bird registration'
);

INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 
  'Pending', NOW()
);

-- Attendee 2: Pending approval with unclear payment
INSERT INTO tbl_transaction (
  user_id, amount, transaction_type, status, proof_image, created_at
) VALUES (
  'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 
  500, 'Event Fee', 'Pending', 'unclear_payment.jpg', NOW()
);

INSERT INTO tbl_transaction_event (
  transaction_id, event_id, remarks
) VALUES (
  LAST_INSERT_ID(), 9998, 'Payment unclear - needs verification'
);

INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, 'cyQuRJT6GaT0Y89NFQua6nMhFJF6E-SAIk_rpryVY1k', 
  'Pending', NOW()
);

-- Attendee 3: Approved registration
INSERT INTO tbl_transaction (
  user_id, amount, transaction_type, status, proof_image, created_at
) VALUES (
  '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 
  500, 'Event Fee', 'Completed', 'clear_payment.jpg', NOW()
);

INSERT INTO tbl_transaction_event (
  transaction_id, event_id, remarks
) VALUES (
  LAST_INSERT_ID(), 9998, 'Payment verified - approved'
);

INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, '_ExbgMDtE-90mt0wLlA74VFYH5I1freBLw4NMY9RcBU', 
  'Registered', NOW()
);

-- Attendee 4: Rejected registration
INSERT INTO tbl_transaction (
  user_id, amount, transaction_type, status, proof_image, created_at
) VALUES (
  'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 
  500, 'Event Fee', 'Failed', 'invalid_payment.jpg', NOW()
);

INSERT INTO tbl_transaction_event (
  transaction_id, event_id, remarks
) VALUES (
  LAST_INSERT_ID(), 9998, 'Payment failed verification - rejected'
);

INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, 'LBmQ-WzvRhVmb55Ucidrc14aL39ae9Ei-7xfbOrPeEA', 
  'Evaluated', NOW()
);

-- Attendee 5: Pending approval with no transaction yet (free event scenario)
INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, '5fb95ed0a0d20daf', 
  'Pending', NOW()
);

-- Attendee 6: Approved for free event
INSERT INTO tbl_event_attendance (
  event_id, user_id, status, created_at
) VALUES (
  9998, '900f929ec408cb4', 
  'Registered', NOW()
);

-- Attendee 7: Attended the event
INSERT INTO tbl_transaction (
  user_id, amount, transaction_type, status, proof_image, created_at
) VALUES (
  '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 
  500, 'Event Fee', 'Completed', 'attended_payment.jpg', NOW()
);

INSERT INTO tbl_transaction_event (
  transaction_id, event_id, remarks
) VALUES (
  LAST_INSERT_ID(), 9998, 'Attended all days'
);

INSERT INTO tbl_event_attendance (
  event_id, user_id, status, time_in, time_out, created_at
) VALUES (
  9998, '6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0', 
  'Attended', '2023-11-15 08:05:23', '2023-11-17 17:30:45', NOW()
);

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

INSERT INTO tbl_application_period(start_date, end_date, start_time, end_time, is_active, created_by) 
VALUES(
"2025-05-24",
"2025-06-20",
"15:24:00",
"10:00:00",
1,
"6mfvyVan6vlls4M78nSj7B5cGt1B7-bSSvPLzT28CQ0"
);

# Register

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
# register




Class Register

SyncIn seamless systems, smart future

Accademics Office:
           Responsibilities:
User roles: Sys Admins.
    • They should be able to add lecturers and assign permissions 
    • They should be able to view registeres submited for the day and other logs 
    • They should be able to schedule class
Lecturers:
           Responsibilities:
User roles: Instructors.
    • They can start a scheduled class
    • they can open the register for students to sign
    • they should be able to generate the QR-code for students to scan
    • they can close/ submit the signed register
Students:
           Responsibilities:
User roles: Sys users.
    • they should be able to login using their school given student ID, Module code, and program
    • when logged in they should be able to scan the generated QR-code while valid
    • the scaned QR-code will submit the student ID and Module code to the DB with the attendance status of present

Login Process:
Normal users, they will use their Username/ Password to authenticate into the system while students: will have to provide their student Id/ Password then they’ll be provided with a default form for the class details which will be used to record their attendance



User Story:
user stories with acceptance criteria for each role (Super User, Lecturer, Student).
    • (Super User): "As a Super User, I can add a new lecturer to the system, providing their name, email, and assigning them the 'Lecturer' role, so they can manage their classes." 
    • (Lecturer): "As a Lecturer, I can view a list of all registers submitted for my classes on a specific day, so I can confirm attendance records."
 
    • (Student): "As a student, I can log in using my student ID and password, so I can access the class attendance system."
           Phase 1: MVP Development (3-5 Sprints)
Each sprint would typically be 2 weeks.
Sprint 1: Foundation & User Management
    • Set up core project structure, CI/CD pipeline, and development environments.
    • Implement user authentication for Super Users and Lecturers (Username/Password).
    • Develop the Super User module to add lecturers and assign permissions.
    • Database schema for Users, Roles, Permissions.
    • Basic logging infrastructure.

Sprint 2: Class Scheduling & Student Login
    • Develop the Super User module for scheduling classes.
    • Implement student login with Student ID/Password.
    • Database schema for Classes, Modules, Programs.
    • Basic UI for Super User class scheduling.

Sprint 3: Lecturer Core Functionality
    • Lecturer ability to start a scheduled class.
    • Lecturer ability to open the register for students to sign.
    • Lecturer ability to generate QR codes.
    • Database schema for Registers, AttendanceRecords.

Sprint 4: Student Attendance & Register Submission
    • Student ability to scan QR code and submit attendance (Student ID, Module Code, Present status)
    • Lecturer ability to close/submit the signed register.
    • Basic viewing of submitted registers for the day for Super Users and Lecturers.

Sprint 5 (Buffer/Refinement):
    • Bug fixing, performance tuning.
    • Refinement of UI/UX based on early feedback.
    • Security hardening (e.g., enforcing password policies).
           Phase 2: Iterative Enhancements & Expansion (Ongoing Sprints)
Based on feedback from the MVP, subsequent sprints would focus on:
    • Reporting & Analytics:
    • 
        ◦ Super User: View daily registers and other logs.
        ◦ Lecturer: Generate specific attendance reports (e.g., for a module over a period).
        ◦ Academic Office: Generate comprehensive attendance reports, identify low attendance.
    • Notifications: Email/SMS for lecturers for scheduled classes, or students for successful attendance.
    • Manual Override: Functionality for lecturers to manually mark attendance with audit trails.
    • Late Arrivals: Differentiating between present and late.
    • Student Attendance History: Students view their own attendance.
    • Integration: Explore integration with SIS for student data, LMS for course data.
    • UI/UX Improvements: Continuous refinement based on user feedback.
    • Scalability & Performance: Load testing and optimization as user base grows.
    • Disaster Recovery Plan: Regular backups and a strategy for data recovery.
           Phase 3: Testing & Deployment
    • Unit Testing: Developers write unit tests for their code.
    • Integration Testing: Verify interactions between different components.
    • System Testing: End-to-end testing of the entire system.
    • User Acceptance Testing (UAT): Key stakeholders (Academics Office, Lecturers, Students) test the system in a production-like environment.
    • Security Audits/Penetration Testing: Engage security specialists to identify vulnerabilities.
    • Deployment Strategy: Automated deployment using CI/CD pipelines to a staging environment first, then production. Plan for zero-downtime deployments.
    • Monitoring & Alerting: Implement robust monitoring for system health, performance, and security events (e.g., using Prometheus, Grafana, ELK stack).
    • Documentation: Comprehensive technical documentation, user manuals, API documentation.









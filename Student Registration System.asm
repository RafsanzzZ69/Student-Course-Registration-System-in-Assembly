; ============================================================
; STUDENT COURSE REGISTRATION SYSTEM
; ============================================================

; Mahir Muntasir Rafsan


.model small
.stack 200h

;  MACRO 1 - print_str
;  Prints a $-terminated string.

print_str MACRO str_addr
    PUSH AX
    PUSH DX
    MOV  AH, 09h
    MOV  DX, OFFSET str_addr
    INT  21h
    POP  DX
    POP  AX
ENDM

;  MACRO 2 - newline
;  Prints CR + LF to move cursor to next line

newline MACRO
    PUSH AX
    PUSH DX
    MOV  AH, 02h
    MOV  DL, 0Dh
    INT  21h
    MOV  DL, 0Ah
    INT  21h
    POP  DX
    POP  AX
ENDM

;  MACRO 3 - print_char
;  Prints one character literal

print_char MACRO ch
    PUSH AX
    PUSH DX
    MOV  AH, 02h
    MOV  DL, ch
    INT  21h
    POP  DX
    POP  AX
ENDM


;  DATA SEGMENT
.data

; --- Constants ---
MAX_STUDENTS EQU 5
MAX_COURSES  EQU 4
NAME_LEN     EQU 16
GRADE_NONE   EQU 0FFh

;Student ID array (5 words)
student_ids   DW 0, 0, 0, 0, 0

; Student name array (5 x 16 bytes = 80 bytes) 
student_names DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
              DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

student_count DW 0

; Course names (4 x 16 bytes)
course_names  DB "Mathematics     "
              DB "Physics         "
              DB "Chemistry       "
              DB "Computer Sci    "

course_max      DW 3, 3, 3, 3
course_enrolled DW 0, 0, 0, 0

;Enrollment map (5 x 4 = 20 bytes)
enroll_map    DB 0,0,0,0
              DB 0,0,0,0
              DB 0,0,0,0
              DB 0,0,0,0
              DB 0,0,0,0

; Grade array (5 x 4 = 20 bytes, 0FFh = no grade) 
grades        DB 0FFh,0FFh,0FFh,0FFh
              DB 0FFh,0FFh,0FFh,0FFh
              DB 0FFh,0FFh,0FFh,0FFh
              DB 0FFh,0FFh,0FFh,0FFh
              DB 0FFh,0FFh,0FFh,0FFh

; Input buffers (DOS format: [maxlen][actlen][data...]) 
input_buf     DB 17, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
num_buf       DB  6, 0, 0,0,0,0,0,0

; Temp variables 
temp_id       DW 0
temp_idx      DW 0FFFFh

; Login credentials (null-terminated)
; Student: user="student" pass="1234"
; Teacher: user="teacher" pass="5678"
login_user_buf  DB 17, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
login_pass_buf  DB 17, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

str_student   DB "student",0
str_teacher   DB "teacher",0
str_pass_stu  DB "1234",0
str_pass_tea  DB "5678",0

; login role result: 1=student, 2=teacher, 0=fail
login_role    DB 0

; New capacity value for teacher feature
new_cap       DW 0

;UI Messages (ends with $) 
msg_title     DB "============================================",13,10,"$"
msg_sys       DB "  STUDENT COURSE REGISTRATION SYSTEM",13,10,"$"
msg_sep       DB "--------------------------------------------",13,10,"$"

; --- Login Messages ---
msg_login_hdr DB "  *** LOGIN ***",13,10,"$"
msg_login_usr DB "  Username: $"
msg_login_pwd DB "  Password: $"
msg_login_bad DB "  [!] Invalid credentials. Try again.",13,10,"$"
msg_login_stu DB "  [OK] Logged in as STUDENT.",13,10,"$"
msg_login_tea DB "  [OK] Logged in as TEACHER.",13,10,"$"
msg_role_ask  DB "  Login as: 1=Student  2=Teacher: $"

; --- Student Menu ---
msg_menu1     DB "  1. Register New Student",13,10,"$"
msg_menu2     DB "  2. Add Course for Student",13,10,"$"
msg_menu3     DB "  3. Drop Course for Student",13,10,"$"
msg_menu4     DB "  4. Enter/Update Grade",13,10,"$"
msg_menu5     DB "  5. Search Student",13,10,"$"
msg_menu6     DB "  6. Enrollment Report",13,10,"$"
msg_menu7     DB "  7. Logout",13,10,"$"
msg_choose    DB "  Choice (1-7): $"

; --- Teacher Menu ---
msg_tmenu_hdr DB "  TEACHER MENU",13,10,"$"
msg_tmenu1    DB "  1. View All Students",13,10,"$"
msg_tmenu2    DB "  2. Set Course Capacity",13,10,"$"
msg_tmenu3    DB "  3. Full Enrollment Report",13,10,"$"
msg_tmenu4    DB "  4. Logout",13,10,"$"
msg_tchoose   DB "  Choice (1-4): $"
msg_cap_ask   DB "  Enter new capacity (1-9): $"
msg_cap_ok    DB "  [OK] Capacity updated!",13,10,"$"
msg_allstu_hdr DB "  === All Registered Students ===",13,10,"$"
msg_stu_id    DB "  ID: $"
msg_stu_nm    DB "  Name: $"
msg_no_stu_any DB "  (No students registered yet)",13,10,"$"

msg_invalid   DB "  [!] Invalid choice!",13,10,"$"
msg_bye       DB "  Goodbye!",13,10,"$"

msg_ent_id    DB "  Enter Student ID: $"
msg_ent_name  DB "  Enter Name: $"
msg_reg_ok    DB "  [OK] Student registered!",13,10,"$"
msg_reg_full  DB "  [!] Student list full!",13,10,"$"
msg_id_dup    DB "  [!] ID already exists!",13,10,"$"

msg_crs_lst   DB "  1=Mathematics 2=Physics 3=Chemistry 4=CompSci",13,10,"$"
msg_crs_sel   DB "  Select course (1-4): $"
msg_add_ok    DB "  [OK] Enrolled!",13,10,"$"
msg_add_full  DB "  [!] Course is FULL!",13,10,"$"
msg_add_dup   DB "  [!] Already enrolled!",13,10,"$"
msg_drop_ok   DB "  [OK] Course dropped!",13,10,"$"
msg_drop_no   DB "  [!] Not enrolled in that course!",13,10,"$"
msg_no_stu    DB "  [!] Student not found!",13,10,"$"

msg_grd_ask   DB "  Enter grade (0-100): $"
msg_grd_ok    DB "  [OK] Grade saved!",13,10,"$"

msg_srch_ask  DB "  Search: 1=By ID  2=By Name: $"
msg_name_ask  DB "  Enter name (partial): $"

msg_prof_hdr  DB "  === Student Profile ===",13,10,"$"
msg_prof_id   DB "  ID   : $"
msg_prof_nm   DB "  Name : $"
msg_prof_crs  DB "  Enrolled Courses:",13,10,"$"
msg_prof_grd  DB "    Grade: $"
msg_prof_non  DB "  (No courses enrolled)",13,10,"$"
msg_na        DB "N/A",13,10,"$"
msg_crlf      DB 13,10,"$"

msg_rpt_hdr   DB "  === Enrollment Report ===",13,10,"$"
msg_seats     DB "  Seats: $"
msg_slash     DB "/$"
msg_full      DB "  [FULL]",13,10,"$"
msg_near      DB "  [NEARLY FULL]",13,10,"$"
msg_stus_hdr  DB "  Students: $"
msg_none_s    DB "(none)",13,10,"$"
msg_total     DB "  Total enrollments: $"

msg_lb        DB "  [$"
msg_rb        DB "] $"

; Individual course name strings (for safe printing)
cn0           DB "Mathematics",13,10,"$"
cn1           DB "Physics",13,10,"$"
cn2           DB "Chemistry",13,10,"$"
cn3           DB "Computer Sci",13,10,"$"

;  CODE SEGMENT
.code


;  MAIN - Entry point: show login, then dispatch to student or teacher menu
main PROC
    MOV  AX, @data
    MOV  DS, AX
    MOV  ES, AX

main_start:
    CALL LoginScreen
    ; login_role: 1=student, 2=teacher
    MOV  AL, [login_role]
    CMP  AL, 1
    JE   go_student_menu
    CMP  AL, 2
    JE   go_teacher_menu
    JMP  main_start          ; retry on 0

go_student_menu:
    CALL StudentMenuLoop
    JMP  main_start          ; back to login after logout

go_teacher_menu:
    CALL TeacherMenuLoop
    JMP  main_start          ; back to login after logout

go_exit:
    print_str msg_bye
    MOV  AH, 4Ch
    INT  21h
main ENDP


; ============================================================
;  PROC: LoginScreen
;  Shows login prompt, asks role, reads username + password,
;  compares against hardcoded credentials.
;  Sets login_role = 1 (student) or 2 (teacher), 0 = fail.
; ============================================================
LoginScreen PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

ls_top:
    print_str msg_title
    print_str msg_sys
    print_str msg_title
    print_str msg_login_hdr
    print_str msg_sep

    ; Ask role choice
    print_str msg_role_ask
    CALL ReadNumber
    CMP  AX, 1
    JE   ls_try_student
    CMP  AX, 2
    JE   ls_try_teacher
    JMP  ls_fail

ls_try_student:
    ; Read and compare password for student
    print_str msg_login_pwd
    MOV  AH, 0Ah
    MOV  DX, OFFSET login_pass_buf
    INT  21h
    newline

    ; Compare entered password with "1234"
    MOV  SI, OFFSET login_pass_buf + 2
    MOV  DI, OFFSET str_pass_stu
    CALL StrCmpZ
    CMP  AX, 1
    JNE  ls_fail

    print_str msg_login_stu
    MOV  BYTE PTR [login_role], 1
    JMP  ls_done

ls_try_teacher:
    ; Read and compare password for teacher
    print_str msg_login_pwd
    MOV  AH, 0Ah
    MOV  DX, OFFSET login_pass_buf
    INT  21h
    newline

    ; Compare entered password with "5678"
    MOV  SI, OFFSET login_pass_buf + 2
    MOV  DI, OFFSET str_pass_tea
    CALL StrCmpZ
    CMP  AX, 1
    JNE  ls_fail

    print_str msg_login_tea
    MOV  BYTE PTR [login_role], 2
    JMP  ls_done

ls_fail:
    print_str msg_login_bad
    MOV  BYTE PTR [login_role], 0
    JMP  ls_top              ; retry

ls_done:
    print_str msg_sep
    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
LoginScreen ENDP


; ============================================================
;  PROC: StrCmpZ
;  Compares null-terminated string at SI with one at DI.
;  Returns AX=1 if equal, AX=0 if not.
;  Also handles DOS buffered input (stops at 0Dh or 0).
; ============================================================
StrCmpZ PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

scz_loop:
    MOV  AL, [SI]
    MOV  BL, [DI]

    ; Treat CR and 0 as end-of-string for SI (DOS input ends with CR)
    CMP  AL, 0Dh
    JE   scz_end_si
    CMP  AL, 0
    JE   scz_end_si
    JMP  scz_cmp_cont

scz_end_si:
    MOV  AL, 0          ; normalize end-of-input to 0

scz_cmp_cont:
    CMP  AL, BL
    JNE  scz_no

    CMP  BL, 0
    JE   scz_yes        ; both ended simultaneously = match

    INC  SI
    INC  DI
    JMP  scz_loop

scz_yes:
    MOV  AX, 1
    JMP  scz_done
scz_no:
    MOV  AX, 0
scz_done:
    POP  DI
    POP  SI
    POP  CX
    POP  BX
    RET
StrCmpZ ENDP


; ============================================================
;  PROC: StudentMenuLoop
;  Original 7-option student menu. Option 7 is now "Logout".
; ============================================================
StudentMenuLoop PROC
    PUSH AX

sml_loop:
    CALL DisplayMenu
    CALL ReadNumber

    CMP  AX, 1
    JE   sml_reg
    CMP  AX, 2
    JE   sml_add
    CMP  AX, 3
    JE   sml_drop
    CMP  AX, 4
    JE   sml_grade
    CMP  AX, 5
    JE   sml_search
    CMP  AX, 6
    JE   sml_report
    CMP  AX, 7
    JE   sml_logout
    print_str msg_invalid
    JMP  sml_loop

sml_reg:
    CALL AddStudent
    JMP  sml_loop
sml_add:
    CALL AddCourse
    JMP  sml_loop
sml_drop:
    CALL DropCourse
    JMP  sml_loop
sml_grade:
    CALL EnterGrade
    JMP  sml_loop
sml_search:
    CALL SearchStudent
    JMP  sml_loop
sml_report:
    CALL ReportGenerator
    JMP  sml_loop
sml_logout:
    POP  AX
    RET
StudentMenuLoop ENDP


; ============================================================
;  PROC: TeacherMenuLoop
;  Teacher menu: View All Students, Set Capacity, Report, Logout
; ============================================================
TeacherMenuLoop PROC
    PUSH AX

tml_loop:
    CALL DisplayTeacherMenu
    CALL ReadNumber

    CMP  AX, 1
    JE   tml_allstu
    CMP  AX, 2
    JE   tml_setcap
    CMP  AX, 3
    JE   tml_report
    CMP  AX, 4
    JE   tml_logout
    print_str msg_invalid
    JMP  tml_loop

tml_allstu:
    CALL ViewAllStudents
    JMP  tml_loop
tml_setcap:
    CALL SetCourseCapacity
    JMP  tml_loop
tml_report:
    CALL ReportGenerator
    JMP  tml_loop
tml_logout:
    POP  AX
    RET
TeacherMenuLoop ENDP


; ============================================================
;  PROC: DisplayTeacherMenu
;  Draws the teacher 4-option menu.
; ============================================================
DisplayTeacherMenu PROC
    PUSH AX
    PUSH DX
    print_str msg_title
    print_str msg_sys
    print_str msg_title
    print_str msg_tmenu_hdr
    print_str msg_sep
    print_str msg_tmenu1
    print_str msg_tmenu2
    print_str msg_tmenu3
    print_str msg_tmenu4
    print_str msg_sep
    print_str msg_tchoose
    POP  DX
    POP  AX
    RET
DisplayTeacherMenu ENDP


; ============================================================
;  TEACHER FEATURE 1: ViewAllStudents
;  Lists all registered students with their IDs and names.
; ============================================================
ViewAllStudents PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    print_str msg_sep
    print_str msg_allstu_hdr
    print_str msg_sep

    MOV  CX, [student_count]
    CMP  CX, 0
    JNE  vas_loop
    print_str msg_no_stu_any
    JMP  vas_done

    MOV  BX, 0              ; BX = student index
vas_loop:
    CMP  BX, [student_count]
    JGE  vas_done

    ; Print ID
    print_str msg_stu_id
    MOV  SI, BX
    SHL  SI, 1
    MOV  AX, [student_ids + SI]
    CALL PrintNumber
    newline

    ; Print Name
    print_str msg_stu_nm
    MOV  AX, BX
    MOV  CX, NAME_LEN
    MUL  CX
    MOV  SI, AX
    MOV  CX, NAME_LEN

vas_name:
    MOV  AL, [student_names + SI]
    CMP  AL, 0
    JE   vas_name_done
    MOV  DL, AL
    MOV  AH, 02h
    INT  21h
    INC  SI
    LOOP vas_name
vas_name_done:
    newline
    print_str msg_sep

    INC  BX
    MOV  CX, [student_count]   ; reload CX (clobbered by MUL)
    JMP  vas_loop

vas_done:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
ViewAllStudents ENDP


; ============================================================
;  TEACHER FEATURE 2: SetCourseCapacity
;  Allows teacher to change the max seats for any course.
; ============================================================
SetCourseCapacity PROC
    PUSH AX
    PUSH BX
    PUSH SI

    print_str msg_sep
    print_str msg_crs_lst
    print_str msg_crs_sel
    CALL ReadNumber
    DEC  AX
    CMP  AX, 3
    JA   scc_done            ; invalid course

    MOV  BX, AX              ; BX = course index (0-based)

    print_str msg_cap_ask
    CALL ReadNumber
    CMP  AX, 0
    JE   scc_done            ; 0 not allowed
    CMP  AX, 9
    JA   scc_done            ; cap at 9

    ; Write new capacity
    MOV  SI, BX
    SHL  SI, 1               ; word offset
    MOV  [course_max + SI], AX
    print_str msg_cap_ok

scc_done:
    POP  SI
    POP  BX
    POP  AX
    RET
SetCourseCapacity ENDP


;  PROC: DisplayMenu
;  Draws the 7-option student menu.
DisplayMenu PROC
    PUSH AX
    PUSH DX
    print_str msg_title
    print_str msg_sys
    print_str msg_title
    print_str msg_menu1
    print_str msg_menu2
    print_str msg_menu3
    print_str msg_menu4
    print_str msg_menu5
    print_str msg_menu6
    print_str msg_menu7
    print_str msg_sep
    print_str msg_choose
    POP  DX
    POP  AX
    RET
DisplayMenu ENDP

;  PROC: AddStudent
;  FEATURE 1 - Register a new student
;  ARRAYS: student_ids, student_names, student_count
;  LOOP:   as_dup_loop (duplicate check), as_copy (name copy)
;  STACK:  PUSH/POP AX BX CX DX SI DI

AddStudent PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Check if array is full
    MOV  AX, [student_count]
    CMP  AX, MAX_STUDENTS
    JL   as_space
    print_str msg_reg_full
    JMP  as_done

as_space:
    ; Read student ID
    print_str msg_ent_id
    CALL ReadNumber
    MOV  [temp_id], AX

    ; --- LOOP: check for duplicate ID ---
    MOV  CX, [student_count]
    CMP  CX, 0
    JE   as_no_dup
    MOV  SI, 0

as_dup_loop:
    MOV  BX, SI
    SHL  BX, 1                  ; word offset = index * 2
    MOV  AX, [student_ids + BX]
    CMP  AX, [temp_id]
    JE   as_is_dup
    INC  SI
    LOOP as_dup_loop
    JMP  as_no_dup

as_is_dup:
    print_str msg_id_dup
    JMP  as_done

as_no_dup:
    ; Store ID into student_ids[count]
    MOV  BX, [student_count]
    SHL  BX, 1
    MOV  AX, [temp_id]
    MOV  [student_ids + BX], AX

    ; Read name
    print_str msg_ent_name
    CALL ReadString

    ; Compute dest offset in student_names: count * NAME_LEN
    MOV  AX, [student_count]
    MOV  BX, NAME_LEN
    MUL  BX                     ; AX = count * 16
    MOV  DI, AX                 ; DI = destination

    MOV  SI, OFFSET input_buf + 2
    MOV  CL, [input_buf + 1]
    MOV  CH, 0
    CMP  CX, 15
    JBE  as_len_ok
    MOV  CX, 15                 ; cap at 15 chars
as_len_ok:

    ; --- LOOP: copy name bytes ---
    CMP  CX, 0
    JE   as_terminate
as_copy:
    MOV  AL, [SI]
    MOV  [student_names + DI], AL
    INC  SI
    INC  DI
    LOOP as_copy

as_terminate:
    MOV  BYTE PTR [student_names + DI], 0   ; null-terminate

    INC  WORD PTR [student_count]
    print_str msg_reg_ok

as_done:
    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
AddStudent ENDP


;  PROC: AddCourse
;  FEATURE 2 - Enroll student in a course
;  ARRAYS: enroll_map, course_enrolled, course_max
;  STACK:  PUSH/POP AX BX CX DX SI

AddCourse PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    print_str msg_ent_id
    CALL ReadNumber
    MOV  [temp_id], AX
    CALL FindStudent
    CMP  AX, 0FFFFh
    JE   ac_nostu
    MOV  [temp_idx], AX

    print_str msg_crs_lst
    print_str msg_crs_sel
    CALL ReadNumber
    DEC  AX                     ; convert 1-based to 0-based
    CMP  AX, 3
    JA   ac_done                ; out of range
    MOV  BX, AX                 ; BX = course index

    ; Check seat availability
    MOV  SI, BX
    SHL  SI, 1                  ; word offset
    MOV  CX, [course_enrolled + SI]
    MOV  DX, [course_max + SI]
    CMP  CX, DX
    JGE  ac_full

    ; Compute flat index: temp_idx * MAX_COURSES + BX
    MOV  AX, [temp_idx]
    MOV  CX, MAX_COURSES
    MUL  CX                     ; AX = temp_idx * 4
    ADD  AX, BX                 ; AX = flat index
    MOV  SI, AX

    ; Check duplicate enrollment
    CMP  BYTE PTR [enroll_map + SI], 1
    JE   ac_dup

    ; Enroll the student
    MOV  BYTE PTR [enroll_map + SI], 1

    ; Increment seat counter
    MOV  SI, BX
    SHL  SI, 1
    INC  WORD PTR [course_enrolled + SI]
    print_str msg_add_ok
    JMP  ac_done

ac_full:
    print_str msg_add_full
    JMP  ac_done
ac_dup:
    print_str msg_add_dup
    JMP  ac_done
ac_nostu:
    print_str msg_no_stu
ac_done:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
AddCourse ENDP


;  PROC: DropCourse
;  FEATURE 3 - Remove student from course
;  ARRAYS: enroll_map, grades, course_enrolled
;  STACK:  PUSH/POP AX BX CX SI

DropCourse PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    print_str msg_ent_id
    CALL ReadNumber
    MOV  [temp_id], AX
    CALL FindStudent
    CMP  AX, 0FFFFh
    JE   dc_nostu
    MOV  [temp_idx], AX

    print_str msg_crs_lst
    print_str msg_crs_sel
    CALL ReadNumber
    DEC  AX
    CMP  AX, 3
    JA   dc_done
    MOV  BX, AX

    ; Flat index
    MOV  AX, [temp_idx]
    MOV  CX, MAX_COURSES
    MUL  CX
    ADD  AX, BX
    MOV  SI, AX

    CMP  BYTE PTR [enroll_map + SI], 1
    JNE  dc_no

    ; Remove enrollment and reset grade
    MOV  BYTE PTR [enroll_map + SI], 0
    MOV  BYTE PTR [grades + SI], GRADE_NONE

    ; Decrement seat counter
    MOV  SI, BX
    SHL  SI, 1
    DEC  WORD PTR [course_enrolled + SI]
    print_str msg_drop_ok
    JMP  dc_done

dc_no:
    print_str msg_drop_no
    JMP  dc_done
dc_nostu:
    print_str msg_no_stu
dc_done:
    POP  SI
    POP  CX
    POP  BX
    POP  AX
    RET
DropCourse ENDP

;  PROC: EnterGrade
;  FEATURE 4 - Store a grade for a student+course
;  ARRAYS: grades, enroll_map
;  STACK:  PUSH/POP AX BX CX SI

EnterGrade PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    print_str msg_ent_id
    CALL ReadNumber
    MOV  [temp_id], AX
    CALL FindStudent
    CMP  AX, 0FFFFh
    JE   eg_nostu
    MOV  [temp_idx], AX

    print_str msg_crs_lst
    print_str msg_crs_sel
    CALL ReadNumber
    DEC  AX
    CMP  AX, 3
    JA   eg_done
    MOV  BX, AX

    ; Flat index
    MOV  AX, [temp_idx]
    MOV  CX, MAX_COURSES
    MUL  CX
    ADD  AX, BX
    MOV  SI, AX

    ; Must be enrolled
    CMP  BYTE PTR [enroll_map + SI], 1
    JNE  eg_no

    ; Read grade
    print_str msg_grd_ask
    CALL ReadNumber
    CMP  AX, 100
    JBE  eg_save
    MOV  AX, 100

eg_save:
    MOV  [grades + SI], AL
    print_str msg_grd_ok
    JMP  eg_done

eg_no:
    print_str msg_drop_no
    JMP  eg_done
eg_nostu:
    print_str msg_no_stu
eg_done:
    POP  SI
    POP  CX
    POP  BX
    POP  AX
    RET
EnterGrade ENDP

;  PROC: SearchStudent
;  FEATURE 5 - Find student by ID or partial name
;  ARRAYS: student_ids, student_names
;  LOOP:   ss_name_loop (scan all students)
;  STACK:  PUSH/POP AX BX CX DX SI


SearchStudent PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    print_str msg_srch_ask
    CALL ReadNumber

    CMP  AX, 1
    JE   ss_id
    CMP  AX, 2
    JE   ss_name
    JMP  ss_done

ss_id:
    print_str msg_ent_id
    CALL ReadNumber
    MOV  [temp_id], AX
    CALL FindStudent
    CMP  AX, 0FFFFh
    JE   ss_notfound
    MOV  [temp_idx], AX
    CALL DisplayProfile
    JMP  ss_done

ss_name:
    print_str msg_name_ask
    CALL ReadString

    MOV  CX, [student_count]
    CMP  CX, 0
    JE   ss_notfound
    MOV  BX, 0              ; student index

    ; --- LOOP: scan all students ---
ss_scan:
    PUSH CX
    PUSH BX

    ; name base offset DX = BX * NAME_LEN
    MOV  AX, BX
    MOV  CX, NAME_LEN
    MUL  CX
    MOV  DX, AX             ; DX = name base

    MOV  SI, OFFSET input_buf + 2
    MOV  CL, [input_buf + 1]
    MOV  CH, 0

    CALL PartialMatch       ; returns AX=1 if matched

    POP  BX
    POP  CX

    CMP  AX, 1
    JNE  ss_next
    MOV  [temp_idx], BX
    CALL DisplayProfile

ss_next:
    INC  BX
    LOOP ss_scan
    JMP  ss_done

ss_notfound:
    print_str msg_no_stu
ss_done:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
SearchStudent ENDP


;  PROC: PartialMatch
;  Helper - checks if typed string SI (length CX) appears
;  anywhere in student_names at base offset DX.
;  Returns AX=1 if match, AX=0 if not.

PartialMatch PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV  BX, 0              ; BX = sliding window position

pm_try:
    MOV  AX, BX
    ADD  AX, CX
    CMP  AX, NAME_LEN
    JA   pm_fail

    PUSH CX
    PUSH SI
    PUSH BX
    PUSH DX

    ADD  DX, BX             ; DX = absolute position in student_names

pm_cmp:
    CMP  CX, 0
    JE   pm_match

    MOV  AL, [SI]           ; typed char
    PUSH BX
    MOV  BX, DX
    MOV  AH, [student_names + BX]   ; stored char
    POP  BX
    CMP  AL, AH
    JNE  pm_mismatch
    INC  SI
    INC  DX
    DEC  CX
    JMP  pm_cmp

pm_match:
    POP  DX
    POP  BX
    POP  SI
    POP  CX
    MOV  AX, 1
    JMP  pm_ret

pm_mismatch:
    POP  DX
    POP  BX
    POP  SI
    POP  CX
    INC  BX
    JMP  pm_try

pm_fail:
    MOV  AX, 0
pm_ret:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    RET
PartialMatch ENDP


;  PROC: DisplayProfile
;  FEATURE 5b - Show full info for student at [temp_idx]
;  ARRAYS: student_ids, student_names, enroll_map, grades
;  LOOP:   dp_cloop (over 4 courses)
;  STACK:  PUSH/POP AX BX CX DX SI DI

DisplayProfile PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    print_str msg_sep
    print_str msg_prof_hdr

    ; Print ID
    print_str msg_prof_id
    MOV  BX, [temp_idx]
    SHL  BX, 1
    MOV  AX, [student_ids + BX]
    CALL PrintNumber
    newline

    ; Print Name: student_names + temp_idx * NAME_LEN
    print_str msg_prof_nm
    MOV  AX, [temp_idx]
    MOV  BX, NAME_LEN
    MUL  BX
    MOV  SI, AX
    MOV  CX, NAME_LEN

dp_name:
    MOV  AL, [student_names + SI]
    CMP  AL, 0
    JE   dp_name_done
    MOV  DL, AL
    MOV  AH, 02h
    INT  21h
    INC  SI
    LOOP dp_name
dp_name_done:
    newline

    print_str msg_prof_crs

    MOV  DI, 0              ; DI = course index
    MOV  BX, 0              ; BX = enrolled count

    ; --- LOOP: iterate 4 courses ---
dp_cloop:
    ; flat index = temp_idx * 4 + DI
    MOV  AX, [temp_idx]
    MOV  CX, MAX_COURSES
    MUL  CX
    ADD  AX, DI
    MOV  SI, AX

    CMP  BYTE PTR [enroll_map + SI], 1
    JNE  dp_skip
    INC  BX

    ; Print "[N] "
    print_str msg_lb
    MOV  AX, DI
    INC  AX
    CALL PrintNumber
    print_str msg_rb

    ; Print course name
    CMP  DI, 0
    JE   dp_n0
    CMP  DI, 1
    JE   dp_n1
    CMP  DI, 2
    JE   dp_n2
    print_str cn3
    JMP  dp_grade
dp_n0: print_str cn0
    JMP  dp_grade
dp_n1: print_str cn1
    JMP  dp_grade
dp_n2: print_str cn2

dp_grade:
    ; Print grade
    print_str msg_prof_grd
    MOV  AL, [grades + SI]
    CMP  AL, GRADE_NONE
    JE   dp_na
    MOV  AH, 0
    CALL PrintNumber
    newline
    JMP  dp_skip

dp_na:
    print_str msg_na

dp_skip:
    INC  DI
    CMP  DI, MAX_COURSES
    JL   dp_cloop

    CMP  BX, 0
    JNE  dp_end
    print_str msg_prof_non

dp_end:
    print_str msg_sep

    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
DisplayProfile ENDP


;  PROC: ReportGenerator
;  FEATURE 6 - Full course enrollment report
;  ARRAYS: course_enrolled, course_max, enroll_map,
;          student_names, student_count
;  LOOP:   rg_cloop (4 courses), rg_sloop (5 students)
;  STACK:  PUSH/POP around all PrintNumber calls to protect DX


ReportGenerator PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    print_str msg_sep
    print_str msg_rpt_hdr
    print_str msg_sep

    MOV  DI, 0              ; DI = course index
    MOV  DX, 0              ; DX = running total (protect with PUSH/POP)

    ; --- LOOP: one iteration per course ---
rg_cloop:
    ; Print "[N] "
    print_str msg_lb
    MOV  AX, DI
    INC  AX
    PUSH DX
    CALL PrintNumber
    POP  DX
    print_str msg_rb

    ; Print course name
    CMP  DI, 0
    JE   rg_n0
    CMP  DI, 1
    JE   rg_n1
    CMP  DI, 2
    JE   rg_n2
    print_str cn3
    JMP  rg_seats
rg_n0: print_str cn0
    JMP  rg_seats
rg_n1: print_str cn1
    JMP  rg_seats
rg_n2: print_str cn2

rg_seats:
    ; Print "Seats: enrolled/max"
    print_str msg_seats
    MOV  SI, DI
    SHL  SI, 1
    MOV  AX, [course_enrolled + SI]
    MOV  BX, AX             ; BX = enrolled
    PUSH DX
    CALL PrintNumber        ; print enrolled count
    POP  DX
    print_str msg_slash
    MOV  AX, [course_max + SI]
    MOV  CX, AX             ; CX = max seats
    PUSH DX
    CALL PrintNumber        ; print max seats
    POP  DX

    ADD  DX, BX             ; accumulate total

    ; Status flag
    CMP  BX, CX
    JGE  rg_isfull
    DEC  CX
    CMP  BX, CX
    JGE  rg_isnear
    newline
    JMP  rg_stulist
rg_isfull:
    print_str msg_full
    JMP  rg_stulist
rg_isnear:
    print_str msg_near

rg_stulist:
    ; List names of enrolled students in this course
    print_str msg_stus_hdr
    MOV  BX, 0              ; BX = student index
    MOV  CX, 0              ; CX = found count

    ; --- LOOP: scan all students for this course ---
rg_sloop:
    CMP  BX, [student_count]
    JGE  rg_sdone

    ; enroll_map[BX * MAX_COURSES + DI]
    PUSH AX
    MOV  AX, BX
    PUSH CX
    MOV  CX, MAX_COURSES
    MUL  CX
    POP  CX
    ADD  AX, DI
    MOV  SI, AX
    POP  AX

    CMP  BYTE PTR [enroll_map + SI], 1
    JNE  rg_snext
    INC  CX

    ; Print this student's name
    PUSH AX
    PUSH DX
    PUSH CX
    MOV  AX, BX
    MOV  CX, NAME_LEN
    MUL  CX
    MOV  SI, AX
    MOV  CX, NAME_LEN

rg_nloop:
    MOV  AL, [student_names + SI]
    CMP  AL, 0
    JE   rg_ndone
    MOV  DL, AL
    MOV  AH, 02h
    INT  21h
    INC  SI
    LOOP rg_nloop
rg_ndone:
    MOV  DL, ' '            ; space between names
    MOV  AH, 02h
    INT  21h
    POP  CX
    POP  DX
    POP  AX

rg_snext:
    INC  BX
    JMP  rg_sloop

rg_sdone:
    CMP  CX, 0
    JNE  rg_hasstus
    print_str msg_none_s
    JMP  rg_cnext
rg_hasstus:
    newline

rg_cnext:
    print_str msg_sep
    INC  DI
    CMP  DI, MAX_COURSES
    JL   rg_cloop

    ; Print total
    print_str msg_total
    MOV  AX, DX
    PUSH DX
    CALL PrintNumber
    POP  DX
    newline
    print_str msg_sep

    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
ReportGenerator ENDP


;  PROC: FindStudent
;  Helper - linear search through student_ids for [temp_id]
;  Returns: AX = array index, or 0FFFFh if not found
;  LOOP: fs_loop


FindStudent PROC
    PUSH BX
    PUSH CX
    PUSH SI

    MOV  CX, [student_count]
    CMP  CX, 0
    JE   fs_no
    MOV  SI, 0

fs_loop:
    MOV  BX, SI
    SHL  BX, 1
    MOV  AX, [student_ids + BX]
    CMP  AX, [temp_id]
    JE   fs_yes
    INC  SI
    LOOP fs_loop

fs_no:
    MOV  AX, 0FFFFh
    JMP  fs_done
fs_yes:
    MOV  AX, SI
fs_done:
    POP  SI
    POP  CX
    POP  BX
    RET
FindStudent ENDP


;  PROC: ReadString
;  DOS buffered keyboard input (INT 21h AH=0Ah)
;  Result placed in input_buf. Length in input_buf[1].

ReadString PROC
    PUSH AX
    PUSH DX
    MOV  AH, 0Ah
    MOV  DX, OFFSET input_buf
    INT  21h
    newline
    POP  DX
    POP  AX
    RET
ReadString ENDP


;  PROC: ReadNumber
;  Reads decimal integer from keyboard, returns it in AX.


ReadNumber PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV  AH, 0Ah
    MOV  DX, OFFSET num_buf
    INT  21h
    newline

    MOV  SI, OFFSET num_buf + 2
    MOV  CL, [num_buf + 1]
    MOV  CH, 0
    MOV  BX, 0              ; BX = accumulator

rn_lp:
    CMP  CX, 0
    JE   rn_done
    MOV  AL, [SI]
    CMP  AL, '0'
    JB   rn_done
    CMP  AL, '9'
    JA   rn_done
    SUB  AL, '0'
    MOV  AH, 0

    ; Save digit count and digit, multiply accumulator by 10
    PUSH CX
    PUSH AX
    MOV  AX, BX
    MOV  CX, 10
    MUL  CX                 ; DX:AX = BX * 10  (CX=10, not DX)
    MOV  BX, AX
    POP  AX
    POP  CX

    ADD  BX, AX             ; BX = BX*10 + new digit
    INC  SI
    DEC  CX
    JMP  rn_lp

rn_done:
    MOV  AX, BX
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    RET
ReadNumber ENDP


;  PROC: PrintNumber
;  Prints AX as decimal. Uses STACK as digit buffer.
;  (Demonstrates explicit stack usage for digit reversal)

PrintNumber PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  BX, 10
    MOV  CX, 0

    CMP  AX, 0
    JNE  pn_div
    ; Special case: zero
    MOV  DL, '0'
    MOV  AH, 02h
    INT  21h
    JMP  pn_done

    ; --- LOOP: divide out digits, push each onto stack ---
pn_div:
    CMP  AX, 0
    JE   pn_print
    MOV  DX, 0
    DIV  BX                 ; AX=quotient, DX=remainder digit
    PUSH DX                 ; push digit (STACK usage)
    INC  CX
    JMP  pn_div

    ; --- LOOP: pop digits in correct order and print ---
pn_print:
    CMP  CX, 0
    JE   pn_done
    POP  DX                 ; pop digit (STACK usage)
    ADD  DL, '0'
    MOV  AH, 02h
    INT  21h
    DEC  CX
    JMP  pn_print

pn_done:
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
PrintNumber ENDP

END main

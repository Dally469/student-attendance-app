# App Store Submission Details — Student Attendance App

Use this document when filling out **App Store Connect** (name, description, keywords, category, review notes, etc.).

---

## 1. App name & identity

| Field | Value |
|-------|--------|
| **App name** | Attendance *(or your preferred name, e.g. "School Attendance")* |
| **Subtitle** (max 30 characters) | Student attendance & school communication |
| **Bundle ID** | Use the same as in Xcode (`ios/Runner.xcodeproj` or project settings) |

---

## 2. Description (for App Store listing)

**Short description / Promotional text** (max 170 characters, editable anytime):

> Record student attendance with NFC or manual check-in, assign student cards, and communicate with parents via SMS and WhatsApp—all from one school app.

**Full description** (max 4000 characters):

> **Attendance** helps schools and teachers manage daily student attendance and stay in touch with parents.
>
> **For teachers and school staff**
> • **Record attendance** — Create attendance sessions per classroom and record check-in/check-out using NFC cards or manual selection. Sessions sync with your school backend.
> • **Assign student cards** — Link NFC cards to students so they can tap to check in and out.
> • **Parent communication** — Send bulk SMS or WhatsApp messages to parents (e.g. reminders, announcements). Messages can include placeholders like student name, school, and classroom.
> • **SMS top-up & balance** — View SMS balance and top-up history used for parent notifications.
>
> **For parents**
> • **Parent login** — Parents can log in to view their children’s information (where supported by your school).
>
> **Technical**
> • Works with your school’s backend (API). Requires valid school credentials.
> • Uses NFC on supported devices to read student cards for quick check-in.
> • Portrait-oriented for easy use in the classroom.
>
> **Ideal for**
> Schools and institutions that use the companion backend and want a single app for attendance, card assignment, and parent communication.

---

## 3. Keywords (max 100 characters, comma-separated, no spaces after commas)

```
attendance,school,students,NFC,check-in,teachers,parent communication,SMS,classroom,education
```

Alternative (if you need to stress different terms):

```
student attendance,school app,NFC,teachers,parents,SMS,classroom,check-in,education
```

---

## 4. Category (primary & optional)

| Field | Recommendation |
|-------|----------------|
| **Primary category** | **Education** |
| **Secondary category** (optional) | **Productivity** or **Business** |

---

## 5. Age rating

- The app is aimed at **teachers and school staff** (and optionally parents), not at children as primary users.
- **Recommended:** Choose the age rating that matches your content (typically **4+** if there is no inappropriate content, or follow the questionnaire in App Store Connect).

---

## 6. What’s new (version 1.0.0)

Use this in the “What’s New in This Version” field for the first release:

> Initial release.
> • Record student attendance (NFC or manual) per classroom  
> • Assign NFC cards to students  
> • Send bulk SMS and WhatsApp messages to parents  
> • View SMS balance and top-up history  
> • Parent login for viewing student information (where supported)

---

## 7. URLs (required for submission)

You must provide:

| URL type | What to add |
|----------|-------------|
| **Support URL** | A working webpage where users can get help (e.g. your website’s contact/support page or a simple “Contact support” page). |
| **Privacy Policy URL** | A working webpage that describes what data the app collects (e.g. login, school/student data, NFC usage) and how it is used and stored. **Required by Apple.** |
| **Marketing URL** (optional) | Your main website or product page. |

Example placeholders (replace with your real URLs):

- Support: `https://yourschoolapp.com/support`
- Privacy: `https://yourschoolapp.com/privacy`

---

## 8. Permissions / capabilities (for Apple and reviewers)

The app uses:

| Capability | Purpose (for App Store / reviewer) |
|------------|------------------------------------|
| **NFC** | Reading NFC tags to assign cards to students and for student check-in. Usage description is set in Info.plist: “Read NFC tags to assign cards to students”. |
| **Network** | All features require internet (login, classrooms, attendance, SMS, parent communication). |
| **Optional: Camera / Photos** | Used if you enable image picker features (e.g. profile or documents). Declare in App Store Connect and in the app’s permission strings if you use them. |

Make sure **Info.plist** includes:

- `NFCReaderUsageDescription`: e.g. “Read NFC tags to assign cards to students” (already present in your project).

---

## 9. Notes for App Review (recommended)

Paste this in **App Review Information → Notes** so the reviewer can test the app:

> **App purpose**  
> This app is for schools using our backend. Teachers/staff log in with school credentials to record attendance (NFC or manual), assign student NFC cards, and send SMS/WhatsApp to parents.
>
> **Testing**  
> • **Login:** Use [provide a test school username and password or test account].  
> • **Backend:** The app requires our backend to be reachable; base URL is configured at build time.  
> • **NFC:** Optional; attendance can be tested without NFC by using manual check-in.  
> • **SMS/WhatsApp:** Require valid API/school configuration; optional for basic review if you only test attendance and navigation.
>
> **Demo account** (if you have one):  
> Username: …  
> Password: …

Fill in the bracketed parts with real test credentials and any demo account you create for Apple.

---

## 10. Checklist before submit

- [ ] App name and subtitle set in App Store Connect.
- [ ] Short and full description added (and within character limits).
- [ ] Keywords added (no spaces after commas, under 100 characters).
- [ ] Primary category set to **Education** (and secondary if desired).
- [ ] Age rating completed in App Store Connect.
- [ ] **Support URL** and **Privacy Policy URL** added and both links work.
- [ ] “What’s New” filled for version 1.0.0.
- [ ] Test account and “Notes for App Review” provided so Apple can log in and test.
- [ ] NFC usage description present in **Info.plist** (already in project).
- [ ] Build uploaded from Xcode/App Store Connect and attached to the version.

---

## 11. One-paragraph summary (for internal or partner use)

**Attendance** is an education app for schools that use its backend. Teachers and staff log in with school credentials to create and run attendance sessions per classroom (NFC card tap or manual check-in/check-out), assign NFC cards to students, and send bulk SMS and WhatsApp messages to parents. The app also supports SMS balance and top-up history, and optional parent login to view student information. It requires internet and uses NFC on supported devices; a privacy policy and support URL are required for App Store submission.

---

*Generated from the student-attendance-app codebase. Update Support URL, Privacy Policy URL, and test account details before submitting.*

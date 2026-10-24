# คู่มือเริ่มงานบนเครื่องใหม่และทำงานร่วมกัน

Repository: https://github.com/champ24m3-ui/workout_planner

คู่มือนี้สำหรับ clone ใหม่บน Windows ใช้ PowerShell จากราก repository
เครื่องเจ้าของโปรเจกต์เดิมให้ใช้ `.venv` และ `backend/.env` ที่มีอยู่ต่อไป
ไม่ต้องสร้างทับหรือย้ายโค้ด Backend

## 1. Clone และอ่านสถานะ

```powershell
git clone https://github.com/champ24m3-ui/workout_planner.git
cd workout_planner
```

อ่าน [README](../README.md), [กติกา](CODING_RULES.md), [แผนงาน](ROADMAP.md)
และเอกสารอื่นใน `docs/` ก่อนแก้ไข ให้ Claude Code อ่าน `CLAUDE.md` และ
`AGENTS.md` ด้วย ประวัติแชตและความจำของ AI ในเครื่องเดิมไม่ได้มากับ Git

Task 2.1 และ 2.2 มีหลักฐานการทดสอบเดิมในขอบเขต local demo
Task 2.3–2.5 และ Frontend ยังไม่เริ่ม ต้องตกลงขอบเขตก่อนเขียน

## 2. Python และ dependencies

ติดตั้ง Git, Python และ MySQL ก่อนเริ่ม สภาพแวดล้อมเดิมระบุ Python 3.13.14
ใน `.venv/pyvenv.cfg` (ตรวจจากไฟล์ตั้งค่า ไม่ใช่การรัน interpreter ใหม่)
ใช้ Python 3.13 เป็นจุดเริ่มต้นเดียวกัน โดยตรวจเวอร์ชัน patch กับเจ้าของงาน
MySQL baseline ระบุ 8.0.16+ แต่ยังไม่ได้ตรวจเวอร์ชันเซิร์ฟเวอร์เดิมในงานส่งต่อนี้
ให้เทียบผล `SELECT VERSION();` ของทั้งสองเครื่อง

เฉพาะ clone ใหม่ที่ยังไม่มี `.venv`:

```powershell
py -3.13 -m venv .venv
```

จากนั้นใช้ interpreter ของโปรเจกต์โดยตรง ไม่จำเป็นต้อง activate:

```powershell
.\.venv\Scripts\python.exe --version
.\.venv\Scripts\python.exe -m pip install -r backend/requirements-dev.txt
```

อย่าคัดลอก `.venv` จากเครื่องเพื่อน เพราะมีพาธและไฟล์เฉพาะเครื่อง
ไฟล์ requirements ปัจจุบันยังไม่ล็อกเวอร์ชัน ดังนั้นผลติดตั้งอาจต่างกัน
ก่อนถือว่าเป็น environment เดียวกัน ให้เปรียบเทียบ `python --version` และ
ผล `.\.venv\Scripts\python.exe -m pip list` ของทั้งคู่และรันทดสอบ
การส่งโครงสร้างครั้งนี้ไม่ได้เพิ่ม lockfile หรือรับรองการติดตั้งบนเครื่องใหม่

## 3. ฐานข้อมูลในเครื่องตัวเอง

Git ส่งไฟล์ SQL แต่ไม่ส่งข้อมูลภายใน MySQL ของเครื่องเจ้าของโปรเจกต์
ใช้ `database/Project_add_Equipment.sql` เป็นไฟล์อ้างอิง baseline
สำเนา `Project_add_Equipment.sql` ที่รากยังเก็บไว้ตามต้นฉบับ ทั้งสองต้องตรงกัน
ไม่ใช่ migration สองชุดและไม่ต้องรันทั้งสองไฟล์

**SQL นี้มี `DROP DATABASE IF EXISTS smart_workout_planner` และจะลบฐานข้อมูล
ชื่อดังกล่าวบนเซิร์ฟเวอร์ที่เชื่อมต่ออยู่** ก่อน import ให้ยืนยันว่าเป็น
MySQL สำหรับพัฒนาในเครื่องที่เลือกไว้ และไม่มีข้อมูลเดิมที่ต้องเก็บ
หากมีฐานข้อมูลอยู่แล้ว ให้หยุดและตกลงวิธีเตรียมข้อมูลกับเจ้าของโปรเจกต์
ห้ามให้ AI รัน SQL reset อัตโนมัติ

เมื่อเลือก environment ใหม่ที่ยอมให้สร้าง baseline ได้แล้ว ให้เปิด SQL ใน
MySQL client และรันตามลำดับใน connection เดียว ตั้งค่าให้หยุดเมื่อ SQL error
ตรวจผล T01–T14 ทุกแถวตาม [README](../README.md#database-setup-and-validation)
และ [ROADMAP](ROADMAP.md#task-15-acceptance-checklist)
ค่าเริ่มต้นมี 11 ตาราง อุปกรณ์ 22 รายการ ท่าระบบ 301 รายการ
และผู้ใช้สาธิต `demo@gmail.com` พร้อมโปรไฟล์และอุปกรณ์สองรายการ

## 4. ตั้งค่า .env ของเครื่องนี้

เฉพาะเมื่อยังไม่มี `backend/.env`:

```powershell
Copy-Item -LiteralPath backend/.env.example -Destination backend/.env
```

เปิด `backend/.env` ใน editor และกรอกทั้งห้าคีย์ด้วยค่าของ MySQL เครื่องนี้:

```dotenv
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_local_mysql_user
DB_PASSWORD='your_local_mysql_password'
DB_NAME=smart_workout_planner
```

ค่าข้างบนเป็นตัวอย่าง ห้าม commit รหัสผ่านจริงหรือส่งในแชต
`backend/config.py` อ่าน `.env` จากตำแหน่ง Backend ไม่ผูกกับชื่อผู้ใช้ Windows
หากมี Environment Variables ชื่อ DB_* ใน process อยู่ จะใช้ค่าเหล่านั้นแทนไฟล์
เมื่อข้อมูลเชื่อมต่อผิด ให้ตรวจค่าบนเครื่องนั้นโดยไม่พิมพ์รหัสผ่านลง log

## 5. ตรวจสอบก่อนพัฒนาต่อ

รันทดสอบแยกฐานข้อมูลก่อน (ใช้ fake connections ไม่ยืนยัน MySQL จริง):

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s backend/tests -v
```

เมื่อเตรียมฐานข้อมูลและ `.env` แล้ว ตรวจ health และเปรียบเทียบ schema/seed
แบบอ่านอย่างเดียว จากนั้นเปิด server:

```powershell
.\.venv\Scripts\python.exe -m backend.verify_live
.\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

เปิด PowerShell อีกหน้าต่างจากราก repository:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/health/db
Invoke-RestMethod http://127.0.0.1:8000/profile
```

Swagger: http://127.0.0.1:8000/docs ปัจจุบันเป็น local demo ไม่มี login
ผลโปรไฟล์ขึ้นกับฐานข้อมูลแต่ละเครื่อง การ push/pull ไม่ sync ข้อมูล MySQL
ผลทดสอบเดิมใน ROADMAP ไม่ใช่หลักฐานว่าเครื่องใหม่นี้ผ่านแล้ว
การทดสอบ MySQL ที่สร้าง/ลบฐานข้อมูลชั่วคราวมีคำอธิบายแยกใน
[backend/README.md](../backend/README.md#task-22--disposable-mysql-acceptance-checks)
ไม่ต้องรันเพื่อจัดโครงสร้าง repository

## 6. ทำงานร่วมกันผ่าน branch

ก่อนเริ่มงาน ตรวจ `git status` และเก็บงานค้างของตัวเองให้เรียบร้อย
แล้วเริ่ม branch ใหม่จาก main ล่าสุด:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/your-task
```

ตกลงว่าแต่ละคนรับผิดชอบงานไหน โดยเฉพาะไฟล์ที่แก้ร่วมกัน
เพิ่มเฉพาะไฟล์ของงาน ตรวจ staged diff แล้ว commit และ push:

```powershell
git status
git add <paths-for-your-task>
git diff --cached
git commit -m "Describe the completed change"
git push -u origin feature/your-task
```

แทน `<paths-for-your-task>` ด้วยพาธจริงก่อนรัน ตรวจว่าไม่มี `.env`, `.venv`,
รหัสผ่าน หรือไฟล์เฉพาะเครื่อง จากนั้นเปิด Pull Request บน GitHub
ให้เพื่อน review และรวมเข้า main เมื่อทดสอบตามขอบเขตผ่าน
อย่า force push เพื่อทับงานของอีกคน

ก่อนส่งต่องาน อัปเดต CHANGELOG และสถานะที่เกี่ยวข้องใน ROADMAP
บอกไฟล์ที่แก้ ขอบเขตที่เสร็จ คำสั่งและผลทดสอบจริง และสิ่งที่ยังค้าง

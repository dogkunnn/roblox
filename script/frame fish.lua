<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ตารางสถานะผู้เล่นแบบเรียลไทม์</title>
    <style>
        body {
            font-family: "Sarabun", "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            background: #f7f9fc;
            margin: 0;
            padding: 20px;
            color: #333;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
        }

        h1 {
            margin-bottom: 30px;
            font-weight: 700;
            color: #2c3e50;
            text-align: center;
            user-select: none;
        }

        .summary {
            display: flex;
            gap: 24px;
            margin-bottom: 25px;
            flex-wrap: wrap;
            justify-content: center;
        }
        .box {
            background: white;
            padding: 18px 28px;
            border-radius: 14px;
            box-shadow: 0 4px 8px rgb(0 0 0 / 0.08);
            min-width: 180px;
            font-weight: 600;
            font-size: 1.15rem;
            text-align: center;
            color: #34495e;
            user-select: none;
            transition: background-color 0.3s ease;
        }
        .box:hover {
            background-color: #e8f0fe;
        }

        /* ตัวกรองและปุ่มบนสุด */
        .top-controls {
            width: 100%;
            max-width: 900px;
            margin-bottom: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        .filter-container {
            min-width: 160px;
            user-select: none;
        }
        label {
            font-weight: 600;
            margin-bottom: 6px;
            display: block;
            color: #34495e;
            font-size: 1rem;
        }
        select, input[type="text"] { /* Added input[type="text"] */
            width: 100%;
            padding: 8px 12px;
            font-size: 1rem;
            border: 2px solid #3498db;
            border-radius: 8px;
            background: white;
            color: #2c3e50;
            cursor: pointer;
            transition: border-color 0.25s ease;
        }
        select:hover, select:focus, input[type="text"]:hover, input[type="text"]:focus { /* Added input[type="text"] */
            border-color: #1d6fa5;
            outline: none;
        }

        .action-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        #delete-selected, #refresh-data {
            padding: 10px 24px;
            font-size: 1.1rem;
            font-weight: 700;
            border: none;
            border-radius: 9px;
            color: white;
            cursor: pointer;
            transition: background-color 0.25s ease;
            user-select: none;
            white-space: nowrap;
            flex-shrink: 0;
        }
        #delete-selected {
            background-color: #e74c3c;
        }
        #delete-selected:disabled {
            background-color: #c0392b;
            cursor: not-allowed;
            opacity: 0.6;
        }
        #refresh-data {
            background-color: #2ecc71; /* Green for refresh */
        }
        #refresh-data:hover {
            background-color: #27ae60;
        }


        table {
            border-collapse: collapse;
            width: 100%;
            max-width: 900px;
            background: white;
            box-shadow: 0 5px 15px rgb(0 0 0 / 0.1);
            border-radius: 10px;
            overflow: hidden;
            user-select: none;
        }
        thead {
            background: #3498db;
            color: white;
            font-weight: 700;
        }
        th, td {
            padding: 14px 18px;
            border-bottom: 1px solid #ddd;
            text-align: center;
            font-size: 1rem;
        }
        tbody tr:hover {
            background-color: #f1f7ff;
        }

        .online {
            color: #27ae60;
            font-weight: 700;
        }
        .offline {
            color: #c0392b;
            font-weight: 700;
        }
        /* New styles for farming status */
        .farming {
            color: #f39c12; /* Orange for farming */
            font-weight: 700;
        }
        .not-farming {
            color: #555; /* Dark grey for not farming */
            font-weight: 500;
        }


        input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }

        /* Custom Alert/Popup */
        .custom-alert {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background-color: #333;
            color: white;
            padding: 15px 30px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.5s ease-in-out;
            max-width: 80%;
            text-align: center;
            font-size: 1.1rem;
        }
        .custom-alert.show {
            opacity: 1;
        }

        /* --- Custom Confirmation Modal Styles --- */
        .custom-modal {
            display: none; /* Hidden by default */
            position: fixed; /* Stay in place */
            z-index: 1001; /* Sit on top of everything */
            left: 0;
            top: 0;
            width: 100%; /* Full width */
            height: 100%; /* Full height */
            overflow: auto; /* Enable scroll if needed */
            background-color: rgba(0,0,0,0.5); /* Black w/ opacity */
            justify-content: center;
            align-items: center;
            padding-top: 50px; /* Offset from top */
        }

        .custom-modal.show {
            display: flex; /* Show when active */
        }

        .modal-content {
            background-color: #fefefe;
            margin: auto;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.2);
            width: 90%;
            max-width: 400px;
            text-align: center;
            transform: scale(0.9);
            opacity: 0;
            transition: all 0.3s ease-out;
        }

        .custom-modal.show .modal-content {
            transform: scale(1);
            opacity: 1;
        }

        .modal-content h3 {
            margin-top: 0;
            color: #2c3e50;
            font-size: 1.5rem;
            margin-bottom: 20px;
        }

        .modal-content p {
            font-size: 1.1rem;
            color: #555;
            margin-bottom: 30px;
            line-height: 1.6;
        }

        .modal-buttons {
            display: flex;
            justify-content: center;
            gap: 15px;
        }

        .modal-button {
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: background-color 0.2s ease, transform 0.1s ease;
            white-space: nowrap;
        }

        .modal-button.confirm {
            background-color: #e74c3c;
            color: white;
        }
        .modal-button.confirm:hover {
            background-color: #c0392b;
            transform: translateY(-2px);
        }

        .modal-button.cancel {
            background-color: #bdc3c7;
            color: #34495e;
        }
        .modal-button.cancel:hover {
            background-color: #95a5a6;
            transform: translateY(-2px);
        }

        /* New Kick button style */
        .kick-button {
            background-color: #3498db; /* Blue */
            color: white;
            border: none;
            padding: 8px 15px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: background-color 0.2s ease;
            white-space: nowrap;
        }
        .kick-button:hover {
            background-color: #2980b9;
        }
        .kick-button:disabled {
            background-color: #9bbcdb;
            cursor: not-allowed;
            opacity: 0.7;
        }


        @media (max-width: 600px) {
            .summary {
                flex-direction: column;
                gap: 15px;
                align-items: center;
            }
            .box {
                width: 100%;
                max-width: 300px;
            }
            .top-controls {
                flex-direction: column;
                align-items: stretch;
            }
            .action-buttons {
                justify-content: center;
                width: 100%;
            }
            #delete-selected, #refresh-data {
                width: 100%;
            }
            table {
                max-width: 100%;
            }
            th, td {
                padding: 10px 12px; /* Adjust padding for smaller screens */
                font-size: 0.9rem;
            }
            .modal-content {
                padding: 20px;
            }
            .modal-button {
                padding: 10px 20px;
                font-size: 1rem;
            }
        }
    </style>
</head>
<body>

    <h1>📊 ตารางสถานะผู้เล่นแบบเรียลไทม์</h1>

    <div class="summary">
        <div class="box" id="total-players-count">👥 ผู้เล่นทั้งหมด: -</div>
        <div class="box" id="total-cash">💰 เงินรวมทั้งหมด: -</div>
        <div class="box" id="total-money">💵 คิดเป็นบาท: -</div>
        <div class="box" id="online-count">🟢 ออนไลน์: -</div>
        <div class="box" id="offline-count">🔴 ออฟไลน์: -</div>
        <div class="box" id="farming-count">🎣 กำลังฟาร์ม: -</div>
        <div class="box" id="not-farming-count">🛋️ ไม่ฟาร์ม: -</div>
    </div>

    <div class="top-controls">
        <div class="filter-container">
            <label for="status-filter">กรองสถานะผู้เล่น</label>
            <select id="status-filter" aria-label="กรองสถานะผู้เล่น">
                <option value="all" selected>ทั้งหมด</option>
                <option value="online">ออนไลน์</option>
                <option value="offline">ออฟไลน์</option>
                <option value="farming">กำลังฟาร์ม</option>
                <option value="not-farming">ไม่ฟาร์ม</option>
            </select>
        </div>

        <div class="filter-container">
            <label for="device-id-filter">กรอง Device ID</label>
            <select id="device-id-filter" aria-label="กรอง Device ID">
                <option value="all" selected>ทั้งหมด</option>
                </select>
        </div>

        <div class="filter-container">
            <label for="sort-cash">เรียงเงิน</label>
            <select id="sort-cash" aria-label="เรียงเงิน">
                <option value="none" selected>ไม่เรียง</option>
                <option value="desc">มากไปน้อย</option>
                <option value="asc">น้อยไปมาก</option>
            </select>
        </div>

        <div class="filter-container">
            <label for="search-username">ค้นหาผู้เล่น</label>
            <input type="text" id="search-username" placeholder="ค้นหาด้วยชื่อผู้ใช้..." aria-label="ค้นหาผู้เล่นด้วยชื่อผู้ใช้" />
        </div>

        <div class="action-buttons">
            <button id="refresh-data">🔄 รีเฟรชข้อมูล</button>
            <button id="delete-selected" disabled>ลบผู้เล่นที่เลือก</button>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 40px;">#</th>
                <th style="width: 36px;"><input type="checkbox" id="select-all" title="เลือกทั้งหมด" aria-label="เลือกทั้งหมด" /></th>
                <th>🧑 Username</th>
                <th>🖥️ Device ID</th> <th>💸 Cash</th>
                <th>👥 Player Count</th>
                <th>📶 Status</th>
                <th>🎣 สถานะฟาร์ม</th>
                <th>🕒 Last Online</th>
                <th>🦶 เตะ!</th>
            </tr>
        </thead>
        <tbody id="player-table">
        </tbody>
    </table>

    <div id="confirm-modal" class="custom-modal">
        <div class="modal-content">
            <h3 id="modal-title">ยืนยันการลบข้อมูล</h3>
            <p id="modal-message">คุณต้องการลบผู้เล่น **X** คนหรือไม่? การดำเนินการนี้ไม่สามารถยกเลิกได้</p>
            <div class="modal-buttons">
                <button class="modal-button cancel" id="modal-cancel">ยกเลิก</button>
                <button class="modal-button confirm" id="modal-confirm">ยืนยันการลบ</button>
            </div>
        </div>
    </div>

    <script>
        const supabaseUrl = "https://inlrteqmzgrnhzibkymh.supabase.co";
        // This key needs 'update' permissions on the 'players' table for the kick feature
        // It's HIGHLY RECOMMENDED to use a secure backend for write/delete operations
        const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlubHJ0ZXFtemdybmh6aWJreW1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDMwNjUsImV4cCI6MjA2MDQxOTA2NX0.fHKi5Cy0RfO65OVedadzCTUi26MTSPN5nKs92zNyYFU";

        const headers = {
            apikey: supabaseKey,
            Authorization: `Bearer ${supabaseKey}`,
            Accept: "application/json",
            "Content-Type": "application/json",
        };

        let playersData = []; // This will hold the raw data from Supabase
        let displayedPlayers = []; // This will hold data after filtering/sorting for rendering

        const OFFLINE_THRESHOLD_SECONDS = 70; // Time in seconds after which a player is considered offline
        const FARMING_OFF_THRESHOLD_SECONDS = 120; // NEW: Time in seconds after which farming status changes to not farming if offline

        let currentFilter = "all";
        let currentDeviceFilter = "all"; // NEW: For Device ID filter
        let currentSort = "none";
        let currentSearchQuery = ""; // NEW: For username search

        const playerTable = document.getElementById("player-table");
        const totalPlayersCountEl = document.getElementById("total-players-count");
        const totalCashEl = document.getElementById("total-cash");
        const totalMoneyEl = document.getElementById("total-money");
        const onlineCountEl = document.getElementById("online-count");
        const offlineCountEl = document.getElementById("offline-count");
        const farmingCountEl = document.getElementById("farming-count");
        const notFarmingCountEl = document.getElementById("not-farming-count");

        const statusFilter = document.getElementById("status-filter");
        const deviceIdFilter = document.getElementById("device-id-filter"); // NEW
        const sortCashSelect = document.getElementById("sort-cash");
        const searchUsernameInput = document.getElementById("search-username"); // NEW
        const deleteBtn = document.getElementById("delete-selected");
        const refreshBtn = document.getElementById("refresh-data");
        const selectAllCheckbox = document.getElementById("select-all");

        // Custom Modal Elements
        const confirmModal = document.getElementById("confirm-modal");
        const modalTitle = document.getElementById("modal-title");
        const modalMessage = document.getElementById("modal-message");
        const modalConfirmBtn = document.getElementById("modal-confirm");
        const modalCancelBtn = document.getElementById("modal-cancel");

        let confirmCallback = null; // Store the function to call on confirm

        function formatMoney(cash) {
            return (cash / 1000000 * 100).toFixed(2) + " บาท";
        }

        function formatRelativeTime(timestamp) {
            if (!timestamp) return "-";

            const now = new Date();
            const past = new Date(timestamp);
            const seconds = Math.floor((now - past) / 1000);

            if (seconds < 0) return "อนาคต?"; // Handle future dates just in case

            if (seconds < 60) {
                return `${seconds} วินาทีที่แล้ว`;
            }

            const minutes = Math.floor(seconds / 60);
            const remainingSeconds = seconds % 60;
            if (minutes < 60) {
                return `${minutes} นาที ${remainingSeconds} วินาทีที่แล้ว`;
            }

            const hours = Math.floor(minutes / 60);
            const remainingMinutes = minutes % 60;
            if (hours < 24) {
                return `${hours} ชั่วโมง ${remainingMinutes} นาทีที่แล้ว`;
            }

            const days = Math.floor(hours / 24);
            const remainingHours = hours % 24;
            return `${days} วัน ${remainingHours} ชั่วโมงที่แล้ว`;
        }

        /**
         * แสดงข้อความแจ้งเตือนแบบ Custom Popup
         * @param {string} message ข้อความที่จะแสดง
         * @param {number} duration ระยะเวลาที่แสดง (มิลลิวินาที)
         */
        function showCustomAlert(message, duration = 5000) {
            console.log(`[ALERT] ${message}`); // Log to console as well
            let alertBox = document.querySelector(".custom-alert");
            if (!alertBox) {
                alertBox = document.createElement("div");
                alertBox.classList.add("custom-alert");
                document.body.appendChild(alertBox);
            }
            alertBox.textContent = message;
            alertBox.classList.add("show");

            setTimeout(() => {
                alertBox.classList.remove("show");
            }, duration);
        }

        function showConfirmModal(title, message, onConfirm) {
            console.log(`[MODAL] แสดงโมดัล: ${title}`);
            modalTitle.textContent = title;
            modalMessage.innerHTML = message;
            confirmCallback = onConfirm;
            confirmModal.classList.add("show");
        }

        modalConfirmBtn.onclick = () => {
            console.log("[MODAL] ยืนยันถูกกด");
            if (confirmCallback) {
                confirmCallback(true);
            }
            confirmModal.classList.remove("show");
            confirmCallback = null;
        };

        modalCancelBtn.onclick = () => {
            console.log("[MODAL] ยกเลิกถูกกด");
            if (confirmCallback) {
                confirmCallback(false);
            }
            confirmModal.classList.remove("show");
            confirmCallback = null;
        };

        confirmModal.onclick = (e) => {
            if (e.target === confirmModal) {
                console.log("[MODAL] คลิกนอกโมดัล");
                if (confirmCallback) {
                    confirmCallback(false);
                }
                confirmModal.classList.remove("show");
                confirmCallback = null;
            }
        };


        async function fetchPlayers() {
            console.log("📡 กำลังดึงข้อมูลผู้เล่นจาก Supabase...");
            try {
                const res = await fetch(`${supabaseUrl}/rest/v1/players?select=*&order=username.asc`, {
                    headers,
                });
                if (!res.ok) {
                    const errorText = await res.text();
                    throw new Error(`Error: ${res.status} ${res.statusText} - ${errorText}`);
                }
                const data = await res.json();
                playersData = data;
                console.log("✅ ดึงข้อมูลสำเร็จ:", playersData.length, "ผู้เล่น");
                populateDeviceIdFilter(); // NEW: Populate device ID filter after fetching
                processAndRenderPlayers(); // Process and render all players
            } catch (error) {
                console.error("❌ ดึงข้อมูลล้มเหลว:", error);
                showCustomAlert("ดึงข้อมูลล้มเหลว: " + error.message, 8000);
            }
        }

        // NEW: Function to populate the device ID filter
        function populateDeviceIdFilter() {
            const deviceIds = new Set(playersData.map(p => p.device_id).filter(id => id)); // Get unique non-null device IDs
            deviceIdFilter.innerHTML = '<option value="all" selected>ทั้งหมด</option>';
            deviceIds.forEach(id => {
                const option = document.createElement("option");
                option.value = id;
                option.textContent = id;
                deviceIdFilter.appendChild(option);
            });
            // Restore previously selected value if it still exists
            if (currentDeviceFilter !== "all" && deviceIds.has(currentDeviceFilter)) {
                deviceIdFilter.value = currentDeviceFilter;
            } else {
                currentDeviceFilter = "all"; // Reset if the previous filter is no longer available
            }
        }


        async function updatePlayerSupabase(username, updates) {
            console.log(`💡 กำลังส่ง PATCH ไป Supabase สำหรับ ${username}:`, updates);
            try {
                const res = await fetch(`${supabaseUrl}/rest/v1/players?username=eq.${encodeURIComponent(username)}`, {
                    method: "PATCH",
                    headers,
                    body: JSON.stringify(updates),
                });
                if (!res.ok) {
                    const errorText = await res.text();
                    throw new Error(`Error: ${res.status} ${res.statusText} - ${errorText}`);
                }
                console.log(`✅ อัปเดตข้อมูลผู้เล่น ${username} สำเร็จ:`, updates);
                // After successful update, we can re-process and re-render
                // to reflect immediate changes if needed, but the periodic fetch
                // might be enough depending on update frequency.
                // For 'kick_player' it's usually one-off, so no re-render needed.
            } catch (error) {
                console.error(`❌ อัปเดตข้อมูลผู้เล่น ${username} ล้มเหลว:`, error);
                showCustomAlert(`อัปเดตผู้เล่น ${username} ล้มเหลว: ${error.message}`, 8000);
            }
        }

        function processAndRenderPlayers() {
            const now = new Date();
            let onlineCount = 0;
            let offlineCount = 0;
            let farmingCount = 0;
            let notFarmingCount = 0;
            let totalCash = 0;

            console.log("🔄 กำลังประมวลผลและแสดงผลข้อมูลผู้เล่น...");

            // First, update statuses in the local playersData based on time
            playersData.forEach(player => {
                const lastOnlineTime = player.last_online ? new Date(player.last_online) : null;
                const diffSeconds = lastOnlineTime ? (now.getTime() - lastOnlineTime.getTime()) / 1000 : Infinity;

                // Update online/offline status
                // A player is offline if last_online is null, or if it's been more than OFFLINE_THRESHOLD_SECONDS
                if (!lastOnlineTime || diffSeconds > OFFLINE_THRESHOLD_SECONDS) {
                    if (player.status !== "offline") {
                        console.log(`[DEBUG STATUS] ผู้เล่น ${player.username}: สถานะเปลี่ยนจาก ${player.status} เป็น offline (นานกว่า ${OFFLINE_THRESHOLD_SECONDS} วินาที)`);
                        player.status = "offline";
                    }
                } else {
                    if (player.status !== "online") {
                        console.log(`[DEBUG STATUS] ผู้เล่น ${player.username}: สถานะเปลี่ยนจาก ${player.status} เป็น online`);
                        player.status = "online";
                    }
                }

                // Update farming status
                // A player is not farming if `is_farming` is explicitly false from Roblox,
                // OR if they are marked as farming but have been offline for > FARMING_OFF_THRESHOLD_SECONDS.
                if (player.is_farming === true && player.status === "offline" && diffSeconds > FARMING_OFF_THRESHOLD_SECONDS) {
                     if (player.is_farming !== false) { // Log only if state actually changes
                        console.log(`[DEBUG FARM] ผู้เล่น ${player.username}: สถานะฟาร์มเปลี่ยนจากกำลังฟาร์มเป็นไม่ฟาร์ม (ออฟไลน์นานกว่า ${FARMING_OFF_THRESHOLD_SECONDS} วินาที)`);
                        player.is_farming = false; // Player is offline, so cannot be farming
                    }
                } else if (player.is_farming === true && player.status === "online" && diffSeconds <= FARMING_OFF_THRESHOLD_SECONDS) {
                    // Player is online and farming, no change needed
                    console.log(`[DEBUG FARM] ผู้เล่น ${player.username}: กำลังฟาร์มและออนไลน์ (อยู่ภายใน ${FARMING_OFF_THRESHOLD_SECONDS} วินาที)`);
                } else if (player.is_farming === false && player.status === "online") {
                     console.log(`[DEBUG FARM] ผู้เล่น ${player.username}: ไม่ฟาร์มและออนไลน์`);
                } else if (player.is_farming === false && player.status === "offline") {
                     console.log(`[DEBUG FARM] ผู้เล่น ${player.username}: ไม่ฟาร์มและออฟไลน์`);
                }
            });

            // Apply filters
            let filteredPlayers = playersData.filter(p => {
                let statusMatch = true;
                if (currentFilter === "online") statusMatch = p.status === "online";
                else if (currentFilter === "offline") statusMatch = p.status === "offline";
                else if (currentFilter === "farming") statusMatch = p.is_farming === true && p.status === "online";
                else if (currentFilter === "not-farming") statusMatch = p.is_farming === false && p.status === "online";

                let deviceMatch = true;
                if (currentDeviceFilter !== "all") {
                    deviceMatch = (p.device_id || "") === currentDeviceFilter;
                }

                let searchMatch = true;
                if (currentSearchQuery) {
                    searchMatch = (p.username || "").toLowerCase().includes(currentSearchQuery.toLowerCase());
                }

                return statusMatch && deviceMatch && searchMatch;
            });

            // Apply sort
            if (currentSort === "desc") {
                filteredPlayers.sort((a, b) => (b.cash || 0) - (a.cash || 0));
            } else if (currentSort === "asc") {
                filteredPlayers.sort((a, b) => (a.cash || 0) - (b.cash || 0));
            }

            displayedPlayers = filteredPlayers; // Set displayedPlayers to the final filtered and sorted list

            playerTable.innerHTML = "";
            displayedPlayers.forEach((player, index) => {
                const username = player.username || "ไม่มีชื่อ";
                const deviceId = player.device_id || "-";
                const cash = player.cash || 0;
                const playercount = player.playercount ?? "-";

                // Determine display status based on processed data
                const statusDisplay = player.status === "online" ? "ออนไลน์" : "ออฟไลน์";
                const statusClass = player.status === "online" ? "online" : "offline";

                const farmingStatusDisplay = player.is_farming ? "กำลังฟาร์ม" : "ไม่ฟาร์ม";
                const farmingStatusClass = player.is_farming ? "farming" : "not-farming";

                const lastOnlineDisplay = formatRelativeTime(player.last_online);

                // Calculate summary counts from the *original* playersData, not the filtered one
                // This ensures total counts reflect all players, not just displayed ones.
                // Recalculate summary totals *before* filtering for display.
            });

            // Recalculate summary counts from the *original* playersData
            onlineCount = 0;
            offlineCount = 0;
            farmingCount = 0;
            notFarmingCount = 0;
            totalCash = 0;

            playersData.forEach(player => {
                totalCash += player.cash || 0;
                if (player.status === "online") {
                    onlineCount++;
                    if (player.is_farming) {
                        farmingCount++;
                    } else {
                        notFarmingCount++;
                    }
                } else {
                    offlineCount++;
                }
            });


            displayedPlayers.forEach((player, index) => {
                const username = player.username || "ไม่มีชื่อ";
                const deviceId = player.device_id || "-";
                const cash = player.cash || 0;
                const playercount = player.playercount ?? "-";

                // Determine display status based on processed data
                const statusDisplay = player.status === "online" ? "ออนไลน์" : "ออฟไลน์";
                const statusClass = player.status === "online" ? "online" : "offline";

                const farmingStatusDisplay = player.is_farming ? "กำลังฟาร์ม" : "ไม่ฟาร์ม";
                const farmingStatusClass = player.is_farming ? "farming" : "not-farming";

                const lastOnlineDisplay = formatRelativeTime(player.last_online);

                const tr = document.createElement("tr");
                tr.innerHTML = `
                    <td>${index + 1}</td>
                    <td><input type="checkbox" class="row-checkbox" data-username="${username}" aria-label="เลือกผู้เล่น ${username}" /></td>
                    <td>${username}</td>
                    <td>${deviceId}</td> <td>${cash.toLocaleString()}</td>
                    <td>${playercount}</td>
                    <td class="${statusClass}">${statusDisplay}</td>
                    <td class="${farmingStatusClass}">${farmingStatusDisplay}</td>
                    <td>${lastOnlineDisplay}</td>
                    <td><button class="kick-button" data-username="${username}" ${player.status !== 'online' ? 'disabled' : ''}>เตะ</button></td>
                `;
                playerTable.appendChild(tr);
            });


            totalPlayersCountEl.innerText = `👥 ผู้เล่นทั้งหมด: ${playersData.length}`;
            totalCashEl.innerText = `💰 เงินรวมทั้งหมด: ${totalCash.toLocaleString()}`;
            totalMoneyEl.innerText = `💵 คิดเป็นบาท: ${formatMoney(totalCash)}`;
            onlineCountEl.innerText = `🟢 ออนไลน์: ${onlineCount}`;
            offlineCountEl.innerText = `🔴 ออฟไลน์: ${offlineCount}`;
            farmingCountEl.innerText = `🎣 กำลังฟาร์ม: ${farmingCount}`;
            notFarmingCountEl.innerText = `🛋️ ไม่ฟาร์ม: ${notFarmingCount}`;

            console.log(`[SUMMARY] ออนไลน์: ${onlineCount}, ออฟไลน์: ${offlineCount}, กำลังฟาร์ม: ${farmingCount}, ไม่ฟาร์ม: ${notFarmingCount}`);


            updateDeleteButtonState();
            updateSelectAllState();
            addCheckboxListeners();
            addKickButtonListeners();
        }

        async function sendKickSignal(username) {
            console.log(`[ACTION] เตรียมส่งสัญญาณเตะผู้เล่น ${username}`);
            showConfirmModal(
                "ยืนยันการเตะผู้เล่น",
                `คุณต้องการเตะผู้เล่น **${username}** ออกจากเกมหรือไม่?`,
                async (confirmed) => {
                    if (!confirmed) {
                        showCustomAlert("การเตะถูกยกเลิก");
                        return;
                    }

                    console.log(`🦶 กำลังส่งสัญญาณเตะผู้เล่น ${username}...`);
                    try {
                        await updatePlayerSupabase(username, { kick_player: true });
                        showCustomAlert(`✅ ส่งสัญญาณเตะ ${username} สำเร็จ!`);
                    } catch (error) {
                        showCustomAlert(`ส่งสัญญาณเตะ ${username} ล้มเหลว: ${error.message}`, 8000);
                    }
                }
            );
        }

        function addKickButtonListeners() {
            document.querySelectorAll(".kick-button").forEach(button => {
                button.removeEventListener("click", handleKickButtonClick); // Prevent duplicate listeners
                button.addEventListener("click", handleKickButtonClick);
            });
        }

        function handleKickButtonClick(event) {
            const usernameToKick = event.currentTarget.dataset.username;
            console.log(`[EVENT] ปุ่มเตะถูกกดสำหรับ ${usernameToKick}`);
            sendKickSignal(usernameToKick);
        }

        function updateDeleteButtonState() {
            const anyChecked = !!document.querySelector(".row-checkbox:checked");
            deleteBtn.disabled = !anyChecked;
            // console.log(`[DEBUG] ปุ่มลบสถานะ: ${deleteBtn.disabled ? 'Disabled' : 'Enabled'}`); // Can uncomment for very verbose debug
        }

        function updateSelectAllState() {
            const checkboxes = document.querySelectorAll(".row-checkbox");
            const checkedBoxes = document.querySelectorAll(".row-checkbox:checked");
            selectAllCheckbox.checked = checkboxes.length > 0 && checkedBoxes.length === checkboxes.length;
            selectAllCheckbox.indeterminate = checkedBoxes.length > 0 && checkedBoxes.length < checkboxes.length;
        }

        function addCheckboxListeners() {
            document.querySelectorAll(".row-checkbox").forEach(checkbox => {
                checkbox.removeEventListener("change", updateDeleteButtonState);
                checkbox.addEventListener("change", () => {
                    updateDeleteButtonState();
                    updateSelectAllState();
                });
            });
        }

        selectAllCheckbox.addEventListener("change", () => {
            console.log(`[EVENT] เลือกทั้งหมด: ${selectAllCheckbox.checked}`);
            const isChecked = selectAllCheckbox.checked;
            document.querySelectorAll(".row-checkbox").forEach(checkbox => {
                checkbox.checked = isChecked;
            });
            updateDeleteButtonState();
        });


        deleteBtn.addEventListener("click", () => {
            const selectedUsernames = Array.from(document.querySelectorAll(".row-checkbox:checked"))
                                                .map(cb => cb.dataset.username);

            if (selectedUsernames.length === 0) {
                showCustomAlert("กรุณาเลือกผู้เล่นที่ต้องการลบ");
                console.warn("[ACTION] พยายามลบแต่ไม่มีผู้เล่นถูกเลือก");
                return;
            }

            console.log(`[ACTION] เตรียมลบผู้เล่น ${selectedUsernames.length} คน: ${selectedUsernames.join(", ")}`);
            showConfirmModal(
                "ยืนยันการลบข้อมูล",
                `คุณต้องการลบผู้เล่น **${selectedUsernames.length}** คนหรือไม่? การดำเนินการนี้ไม่สามารถยกเลิกได้`,
                async (confirmed) => {
                    if (confirmed) {
                        console.log(`🗑️ กำลังดำเนินการลบผู้เล่น: ${selectedUsernames.join(", ")}`);
                        try {
                            const deletePromises = selectedUsernames.map(username =>
                                fetch(`${supabaseUrl}/rest/v1/players?username=eq.${encodeURIComponent(username)}`, {
                                    method: "DELETE",
                                    headers,
                                })
                            );
                            const responses = await Promise.all(deletePromises);

                            const failedDeletions = responses.filter(res => !res.ok);
                            if (failedDeletions.length > 0) {
                                throw new Error(`${failedDeletions.length} รายการลบไม่สำเร็จ`);
                            }

                            showCustomAlert(`✅ ลบผู้เล่น ${selectedUsernames.length} คนสำเร็จ!`);
                            console.log(`✅ ลบผู้เล่น ${selectedUsernames.length} คนสำเร็จ.`);
                            fetchPlayers(); // Re-fetch to update the table
                        } catch (error) {
                            console.error("❌ การลบล้มเหลว:", error);
                            showCustomAlert(`การลบล้มเหลว: ${error.message}`, 8000);
                        }
                    } else {
                        showCustomAlert("การลบถูกยกเลิก");
                        console.log("[ACTION] การลบถูกยกเลิกโดยผู้ใช้");
                    }
                }
            );
        });

        // Event listener for the new refresh button
        refreshBtn.addEventListener("click", () => {
            console.log("[ACTION] ปุ่มรีเฟรชถูกกด");
            fetchPlayers();
            showCustomAlert("ข้อมูลถูกรีเฟรชแล้ว!");
        });

        statusFilter.addEventListener("change", (event) => {
            currentFilter = event.target.value;
            console.log(`[FILTER] เปลี่ยนตัวกรองสถานะเป็น: ${currentFilter}`);
            processAndRenderPlayers();
        });

        // NEW: Event listener for Device ID filter
        deviceIdFilter.addEventListener("change", (event) => {
            currentDeviceFilter = event.target.value;
            console.log(`[FILTER] เปลี่ยนตัวกรอง Device ID เป็น: ${currentDeviceFilter}`);
            processAndRenderPlayers();
        });

        sortCashSelect.addEventListener("change", (event) => {
            currentSort = event.target.value;
            console.log(`[SORT] เปลี่ยนการเรียงเงินเป็น: ${currentSort}`);
            processAndRenderPlayers();
        });

        // NEW: Event listener for Username search input
        searchUsernameInput.addEventListener("input", (event) => {
            currentSearchQuery = event.target.value.trim();
            console.log(`[SEARCH] ค้นหาชื่อผู้เล่น: "${currentSearchQuery}"`);
            processAndRenderPlayers();
        });


        // Initial fetch and periodic updates
        fetchPlayers();
        // Set an interval to fetch and update data every 30 seconds
        setInterval(fetchPlayers, 30000); // Calls fetchPlayers() which then calls processAndRenderPlayers()

    </script>
</body>
</html>

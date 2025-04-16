import os
import threading
import asyncio
import json
import requests
from flask import Flask, request, jsonify
import discord
from discord.ext import commands

# Flask App
app = Flask(__name__)

DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

# URL ของไฟล์ JSON บน GitHub
GITHUB_URL = "https://raw.githubusercontent.com/dogkunnn/roblox/main/players_data.json"
GITHUB_RAW_API = "https://api.github.com/repos/dogkunnn/roblox/contents/players_data.json"

# ฟังก์ชันเพื่อดึงข้อมูลจาก GitHub
def fetch_data_from_github():
    try:
        response = requests.get(GITHUB_URL)
        if response.status_code == 200:
            return response.json()  # คืนค่าข้อมูล JSON ที่ดึงมา
        else:
            return {}
    except Exception as e:
        print("Error fetching data from GitHub:", e)
        return {}

# ฟังก์ชันเพื่อเขียนข้อมูลกลับไปที่ GitHub
def write_data_to_github(data):
    try:
        headers = {
            "Authorization": f"token {os.getenv('GITHUB_TOKEN')}",  # ใช้ GitHub Token ของคุณ
            "Content-Type": "application/json"
        }
        sha = "0967ef424bce6791893e9a57bb952f80fd536e93"  # ใส่ SHA ที่ได้ตรงนี้
        # ดึงข้อมูล SHA ของไฟล์ใน repository ปัจจุบัน
        response = requests.get(GITHUB_RAW_API)
        if response.status_code == 200:
            sha = response.json().get('sha')
        else:
            print(f"Failed to get SHA. Status code: {response.status_code}")
            return

        payload = {
            "message": "Update player data",
            "content": json.dumps(data, indent=4),  # ข้อมูลที่อัปเดต
            "sha": sha  # ต้องใส่ sha ของไฟล์ที่ต้องการแก้ไข
        }

        api_url = "https://api.github.com/repos/dogkunnn/roblox/contents/players_data.json"
        response = requests.put(api_url, headers=headers, json=payload)

        if response.status_code == 200:
            print("Data successfully written to GitHub.")
        else:
            print(f"Failed to write data to GitHub. Status code: {response.status_code}")
    except Exception as e:
        print("Error writing data to GitHub:", e)

player_data = fetch_data_from_github()  # โหลดข้อมูลจาก GitHub เมื่อเริ่มรัน
main_message = None  # กำหนดค่าเริ่มต้นให้กับ main_message

@app.route('/')
def home():
    return jsonify({
        "message": "Bot is running!",
        "recent_data": list(player_data.values())[-5:]
    })

@app.route('/update', methods=['POST'])
def update():
    data = request.json
    username = data.get("username")
    if username:
        player_data[username] = data  # แทนที่ข้อมูลผู้เล่นเดิม
        print(f"Updated data for {username}: {data}")
        write_data_to_github(player_data)  # เขียนข้อมูลไปที่ GitHub หลังจากอัปเดต
    return {"status": "ok", "received": data}

# Discord UI Dropdown
class PlayerDropdown(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)
        self.update_options()

    def update_options(self):
        self.clear_items()
        if player_data:
            self.add_item(PlayerSelect())

class PlayerSelect(discord.ui.Select):
    def __init__(self):
        options = [
            discord.SelectOption(label=username, description=f"ดูข้อมูลของ {username}")
            for username in player_data
        ]
        options.append(discord.SelectOption(label="ดูข้อมูลทั้งหมด", description="ดูข้อมูลของผู้เล่นทุกคน"))
        super().__init__(placeholder="เลือกชื่อผู้เล่น", options=options)

    async def callback(self, interaction: discord.Interaction):
        selected_username = self.values[0]
        
        # ตรวจสอบว่าเลือก "ดูข้อมูลทั้งหมด" หรือไม่
        if selected_username == "ดูข้อมูลทั้งหมด":
            embed = discord.Embed(title="ข้อมูลผู้เล่นทั้งหมด", color=discord.Color.blue())
            for username, data in player_data.items():
                # ตรวจสอบว่า data เป็น dictionary ที่มีคีย์ 'cash', 'serverName', และ 'playerCount'
                if isinstance(data, dict) and 'cash' in data and 'serverName' in data and 'playerCount' in data:
                    embed.add_field(
                        name=username, 
                        value=f"จำนวนเงิน: {data['cash']}\nชื่อเซิร์ฟเวอร์: {data['serverName']}\nจำนวนผู้เล่นในเซิร์ฟเวอร์: {data['playerCount']}",
                        inline=False
                    )
                else:
                    embed.add_field(
                        name=username,
                        value="ข้อมูลไม่ครบถ้วน",
                        inline=False
                    )
            await interaction.response.edit_message(embed=embed, view=self.view)
        else:
            data = player_data.get(selected_username)
            if data and isinstance(data, dict) and 'cash' in data and 'serverName' in data and 'playerCount' in data:
                embed = discord.Embed(title=f"ข้อมูลของ {selected_username}", color=discord.Color.green())
                embed.add_field(name="จำนวนเงิน", value=data['cash'], inline=False)
                embed.add_field(name="จำนวนผู้เล่นในเซิร์ฟเวอร์", value=str(data['playerCount']), inline=False)
                embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data['serverName'], inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)
            else:
                embed = discord.Embed(title=f"ข้อมูลของ {selected_username}", color=discord.Color.red())
                embed.add_field(name="ข้อมูลไม่ครบถ้วน", value="ข้อมูลที่จำเป็นไม่ครบถ้วนหรือยังไม่ได้รับการอัปเดต", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)

async def send_main_message():
    global main_message
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    if main_message is None:
        embed = discord.Embed(title="ข้อมูลผู้เล่น Roblox", description="เลือกชื่อเพื่อดูรายละเอียด", color=discord.Color.blue())
        view = PlayerDropdown()
        main_message = await channel.send(embed=embed, view=view)

    while True:
        if main_message:
            view = PlayerDropdown()
            embed = discord.Embed(title="ข้อมูลผู้เล่น Roblox", description="เลือกชื่อเพื่อดูรายละเอียด", color=discord.Color.blue())
            await main_message.edit(embed=embed, view=view)
        await asyncio.sleep(20)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)
    

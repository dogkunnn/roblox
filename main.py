import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands
from supabase import create_client, Client
import time

# Flask App
app = Flask(__name__)

DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

# Supabase Setup
SUPABASE_URL = "https://inlrteqmzgrnhzibkymh.supabase.co"
SUPABASE_API_KEY = os.getenv("SUPABASE_API_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_API_KEY)

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

# ฟังก์ชันเพื่อดึงข้อมูลจาก Supabase
def fetch_data_from_supabase():
    try:
        response = supabase.table("players").select("*").execute()
        print("Supabase response:", response)  # ตรวจสอบข้อมูลที่ได้รับจาก Supabase
        if response.data:
            return {player['username']: player for player in response.data}
        else:
            print(f"Error fetching data from Supabase: No data found")
            return {}
    except Exception as e:
        print("Error fetching data from Supabase:", e)
        return {}

# ฟังก์ชันเพื่อเขียนข้อมูลกลับไปที่ Supabase
def write_data_to_supabase(data):
    try:
        for username, player in data.items():
            response = supabase.table("players").upsert(player, on_conflict=["username"]).execute()  # ใช้ on_conflict
            print("Supabase response:", response)  # ตรวจสอบข้อมูลที่ได้รับจาก Supabase
            if response.data:
                print(f"Updated data for {username}")
            else:
                print(f"Failed to update data for {username}. Status code: {response.status_code}")
    except Exception as e:
        print("Error writing data to Supabase:", e)

player_data = fetch_data_from_supabase()  # โหลดข้อมูลจาก Supabase เมื่อเริ่มรัน
main_message = None  # กำหนดค่าเริ่มต้นให้กับ main_message

# กำหนดเวลาอัปเดตล่าสุด
last_update_time = {username: time.time() for username in player_data.keys()}

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
        last_update_time[username] = time.time()  # อัปเดตเวลาล่าสุด
        print(f"Updated data for {username}: {data}")
        write_data_to_supabase(player_data)  # เขียนข้อมูลไปที่ Supabase หลังจากอัปเดต
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
            discord.SelectOption(
                label=f"{i+1}: {username} {'🟢' if time.time() - last_update_time[username] <= 60 else '🔴'}", 
                description=f"ดูข้อมูลของ {username}")
            for i, username in enumerate(player_data)
        ]
        options.append(discord.SelectOption(label="ดูข้อมูลทั้งหมด", description="ดูข้อมูลของผู้เล่นทุกคน"))
        super().__init__(placeholder="เลือกชื่อผู้เล่น", options=options)

    async def callback(self, interaction: discord.Interaction):
        selected_username = self.values[0]
        
        # Strip the status icon (🟢 or 🔴) from the selected username
        clean_username = selected_username.split(' ')[0]  # Get the part before the status icon
        
        # ตรวจสอบว่าเลือก "ดูข้อมูลทั้งหมด" หรือไม่
        if clean_username == "ดูข้อมูลทั้งหมด":
            embed = discord.Embed(title="ข้อมูลผู้เล่นทั้งหมด", color=discord.Color.blue())
            for username, data in player_data.items():
                status_icon = '🟢' if time.time() - last_update_time[username] <= 60 else '🔴'
                embed.add_field(
                    name=f"{username} {status_icon}", 
                    value=f"จำนวนเงิน: {data['cash']}\nชื่อเซิร์ฟเวอร์: {data['servername']}\nจำนวนผู้เล่นในเซิร์ฟเวอร์: {data['playercount']}",
                    inline=False
                )
            await interaction.response.edit_message(embed=embed, view=self.view)
        else:
            data = player_data.get(clean_username)
            status_icon = '🟢' if time.time() - last_update_time[clean_username] <= 60 else '🔴'
            if data and isinstance(data, dict) and 'cash' in data and 'servername' in data and 'playercount' in data:
                embed = discord.Embed(title=f"ข้อมูลของ {clean_username}", color=discord.Color.green())
                embed.add_field(name="จำนวนเงิน", value=data['cash'], inline=False)
                embed.add_field(name="จำนวนผู้เล่นในเซิร์ฟเวอร์", value=str(data['playercount']), inline=False)
                embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data['servername'], inline=False)
                embed.add_field(name="สถานะ", value=f"สถานะ: {status_icon}", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)
            else:
                embed = discord.Embed(title=f"ข้อมูลของ {clean_username}", color=discord.Color.red())
                embed.add_field(name="ข้อมูลไม่ครบถ้วน", value="ข้อมูลที่จำเป็นไม่ครบถ้วนหรือยังไม่ได้รับการอัปเดต", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)

# ฟังก์ชันตรวจสอบสถานะออนไลน์
async def check_player_status():
    while True:
        for username in list(player_data.keys()):
            if time.time() - last_update_time[username] > 60:  # ถ้าไม่มีการอัปเดตข้อมูลภายใน 1 นาที
                player_data[username]['status'] = 'ออฟไลน์'  # อัพเดตสถานะเป็นออฟไลน์
            else:
                player_data[username]['status'] = 'ออนไลน์'  # หากอัปเดตแล้วถือว่าออนไลน์
        await asyncio.sleep(60)  # ตรวจสอบทุกๆ 60 วินาที

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
    bot.loop.create_task(check_player_status())  # เริ่มฟังก์ชันตรวจสอบสถานะออนไลน์
    bot.run(DISCORD_TOKEN)


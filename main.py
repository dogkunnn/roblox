import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands
from supabase import create_client, Client
import time
import sys
print("Python version:", sys.version)

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

# Load from Supabase
def fetch_data_from_supabase():
    try:
        response = supabase.table("players").select("*").execute()
        if response.data:
            return {player['username']: player for player in response.data}
        else:
            return {}
    except Exception as e:
        print("Error fetching data from Supabase:", e)
        return {}

# Write to Supabase (ลบทันทีถ้าข้อมูลไม่ตรง และเพิ่มข้อมูลใหม่)
def write_data_to_supabase(data):
    try:
        for username, player in data.items():
            player.pop("status", None)

            existing_data = supabase.table("players").select("*").eq("username", username).execute()
            if existing_data.data:
                existing_player = existing_data.data[0]
                if (existing_player['servername'] != player['servername'] or
                    existing_player['cash'] != player['cash'] or
                    existing_player['playercount'] != player['playercount']):
                    supabase.table("players").delete().eq("username", username).execute()

            supabase.table("players").upsert(player).execute()
    except Exception as e:
        print("Error writing data to Supabase:", e)

player_data = fetch_data_from_supabase()
main_message = None
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
        data.pop("status", None)
        player_data[username] = data
        last_update_time[username] = time.time()
        write_data_to_supabase({username: data})
    return {"status": "ok", "received": data}

# Discord Dropdown
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

        if selected_username == "ดูข้อมูลทั้งหมด":
            embed = discord.Embed(title="ข้อมูลผู้เล่นทั้งหมด", color=discord.Color.blue())
            for username, data in player_data.items():
                status_icon = '🟢' if time.time() - last_update_time[username] <= 60 else '🔴'
                time_diff = int((time.time() - last_update_time[username]) / 60)
                embed.add_field(
                    name=f"{username} {status_icon}",
                    value=f"จำนวนเงิน: {data['cash']}\nชื่อเซิร์ฟเวอร์: {data['servername']}\nจำนวนผู้เล่นในเซิร์ฟเวอร์: {data['playercount']}\nอัพเดทล่าสุด: {time_diff} นาทีที่แล้ว",
                    inline=False
                )
            await interaction.response.edit_message(embed=embed, view=self.view)
        else:
            clean_username = selected_username.split(' ')[1]
            data = player_data.get(clean_username)
            status_icon = '🟢' if time.time() - last_update_time[clean_username] <= 60 else '🔴'
            time_diff = int((time.time() - last_update_time[clean_username]) / 60)
            if data and all(k in data for k in ['cash', 'servername', 'playercount']):
                embed = discord.Embed(title=f"ข้อมูลของ {clean_username}", color=discord.Color.green())
                embed.add_field(name="จำนวนเงิน", value=data['cash'], inline=False)
                embed.add_field(name="จำนวนผู้เล่นในเซิร์ฟเวอร์", value=str(data['playercount']), inline=False)
                embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data['servername'], inline=False)
                embed.add_field(name="สถานะ", value=f"{status_icon}", inline=False)
                embed.add_field(name="อัพเดทล่าสุด", value=f"{time_diff} นาทีที่แล้ว", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)
            else:
                embed = discord.Embed(title=f"ข้อมูลของ {clean_username}", color=discord.Color.red())
                embed.add_field(name="ข้อมูลไม่ครบถ้วน", value="ข้อมูลที่จำเป็นไม่ครบถ้วนหรือยังไม่ได้รับการอัปเดต", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)

# ตรวจสอบสถานะออนไลน์
async def check_player_status():
    while True:
        for username in list(player_data.keys()):
            if time.time() - last_update_time[username] > 60:
                player_data[username]['status'] = 'ออฟไลน์'
            else:
                player_data[username]['status'] = 'ออนไลน์'
        await asyncio.sleep(60)

# แสดงข้อความหลัก
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

# Start Flask + Bot
def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.loop.create_task(check_player_status())
    bot.run(DISCORD_TOKEN)


import os
import threading
import asyncio
from flask import Flask, request
import discord

# สร้าง Flask app
app = Flask(__name__)

# ดึง Discord Token จาก Environment Variable
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716  # ใส่ channel ID ที่คุณต้องการให้บอทส่งข้อความ

# สร้าง Discord Bot
intents = discord.Intents.default()
bot = discord.Client(intents=intents)

latest_data = None

@app.route('/')
def home():
    return "Bot is running!"

@app.route('/update', methods=['POST'])
def update():
    global latest_data
    latest_data = request.json
    return {"status": "ok"}

async def send_loop():
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)
    last_sent = None

    while True:
        global latest_data
        if latest_data and latest_data != last_sent:
            msg = (
                f"**ชื่อผู้เล่น:** {latest_data['username']}\n"
                f"**จำนวนเงิน:** {latest_data['cash']}\n"
                f"**จำนวนผู้เล่นในเซิร์ฟเวอร์:** {latest_data['playerCount']}\n"
                f"**ชื่อเซิร์ฟเวอร์:** {latest_data['serverName']}"
            )
            await channel.send(msg)
            last_sent = latest_data
        await asyncio.sleep(10)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_loop())
    bot.run(DISCORD_TOKEN)

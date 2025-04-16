import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord

app = Flask(__name__)
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

intents = discord.Intents.default()
bot = discord.Client(intents=intents)

latest_data = None
data_log = []  # สำหรับเก็บ log ล่าสุดหลายรายการ (จะโชว์หน้าเว็บ)

@app.route('/')
def home():
    return jsonify({
        "message": "Bot is running!",
        "recent_data": data_log[-5:]  # แสดงล่าสุด 5 รายการ
    })

@app.route('/update', methods=['POST'])
def update():
    global latest_data
    latest_data = request.json
    data_log.append(latest_data)
    print("Data received from Roblox:", latest_data)
    return {"status": "ok", "received": latest_data}

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
            print("Sending message to Discord...")
            await channel.send(msg)
            print("Message sent.")
            last_sent = latest_data
        await asyncio.sleep(10)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_loop())
    bot.run(DISCORD_TOKEN)
    

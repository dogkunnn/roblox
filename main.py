from flask import Flask, request
import discord
import asyncio
import threading

app = Flask(__name__)
intents = discord.Intents.default()
client = discord.Client(intents=intents)
DISCORD_TOKEN = "YOUR_DISCORD_TOKEN"
CHANNEL_ID = 1362080053583937716  # เปลี่ยนเป็น channel id จริง

latest_data = None

@app.route('/update', methods=['POST'])
def update():
    global latest_data
    latest_data = request.json
    return {"status": "ok"}

async def send_loop():
    await client.wait_until_ready()
    channel = client.get_channel(CHANNEL_ID)
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
    client.loop.create_task(send_loop())
    client.run(DISCORD_TOKEN)


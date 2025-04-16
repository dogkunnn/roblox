import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands

# ======== Flask Setup ========
app = Flask(__name__)
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")  # ใช้ .env หรือ os.environ
CHANNEL_ID = 1362080053583937716

player_data = {}  # เก็บข้อมูลผู้เล่น (key = username)
main_message = None

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
        player_data[username] = data  # เก็บล่าสุด
        print(f"[DATA UPDATED] {username}:", data)
    return {"status": "ok", "received": data}


# ======== Discord Bot ========
intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

class PlayerSelect(discord.ui.Select):
    def __init__(self):
        # ดึงชื่อผู้เล่นล่าสุด ไม่ซ้ำ ไม่เกิน 25 รายการ
        seen = set()
        usernames = []
        for username in reversed(list(player_data.keys())):
            if username not in seen:
                seen.add(username)
                usernames.append(username)
            if len(usernames) >= 25:
                break

        options = [
            discord.SelectOption(label=u, description="ดูข้อมูล", emoji="🎮")
            for u in usernames
        ]

        super().__init__(
            placeholder="เลือกชื่อผู้เล่น...",
            min_values=1,
            max_values=1,
            options=options
        )

    async def callback(self, interaction: discord.Interaction):
        username = self.values[0]
        data = player_data.get(username)

        if data:
            embed = discord.Embed(
                title=f"ข้อมูลของ {username}",
                color=discord.Color.from_rgb(200, 230, 255)
            )
            embed.add_field(name="💰 จำนวนเงิน", value=f"`{data['cash']}`", inline=False)
            embed.add_field(name="👥 ผู้เล่นในเซิร์ฟเวอร์", value=f"`{data['playerCount']}`", inline=False)
            embed.add_field(name="🖥️ เซิร์ฟเวอร์", value=f"`{data['serverName']}`", inline=False)
            embed.set_footer(text="ข้อมูลจาก Roblox - อัปเดตเรียลไทม์")
            await interaction.response.edit_message(embed=embed, view=self.view)


class PlayerDropdown(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)
        self.update_dropdown()

    def update_dropdown(self):
        self.clear_items()
        self.add_item(PlayerSelect())


async def send_main_message():
    global main_message
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    if main_message is None:
        embed = discord.Embed(
            title="ข้อมูลผู้เล่น Roblox",
            description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด",
            color=discord.Color.blue()
        )
        main_view = PlayerDropdown()
        main_message = await channel.send(embed=embed, view=main_view)

    while True:
        if main_message:
            view = PlayerDropdown()
            embed = discord.Embed(
                title="ข้อมูลผู้เล่น Roblox",
                description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด",
                color=discord.Color.blue()
            )
            await main_message.edit(embed=embed, view=view)
        await asyncio.sleep(15)


def start_flask():
    app.run(host="0.0.0.0", port=10000)


# ======== Entry Point ========
if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)
        

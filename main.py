import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands

# Flask App
app = Flask(__name__)

DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

player_data = {}  # เก็บข้อมูลโดยใช้ username เป็น key
main_message = None  # ข้อความหลักที่เราจะแก้ไข

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
    return {"status": "ok", "received": data}

# Discord UI Dropdown
class PlayerDropdown(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)
        self.update_options()

    def update_options(self):
        self.clear_items()
        if player_data:
            options = [
                discord.SelectOption(label="ดูข้อมูลทั้งหมด", value="all", description="แสดงข้อมูลของผู้เล่นทั้งหมด"),
                *[discord.SelectOption(label=username, description=f"ดูข้อมูลของ {username}") for username in player_data]
            ]
            self.add_item(PlayerSelect(options=options))

class PlayerSelect(discord.ui.Select):
    def __init__(self, options):
        super().__init__(placeholder="เลือกดูข้อมูลผู้เล่น", options=options)

    async def callback(self, interaction: discord.Interaction):
        selected_value = self.values[0]
        if selected_value == "all":
            if player_data:
                embed = discord.Embed(title="ข้อมูลผู้เล่นทั้งหมด", color=discord.Color.gold())
                for username, data in player_data.items():
                    embed.add_field(name=f"**{username}**", value=f"**เงิน:** {data['cash']}\n**เซิร์ฟเวอร์:** {data['serverName']}\n**ID:** {data.get('playerId', 'N/A')}", inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)
            else:
                await interaction.response.edit_message(content="ไม่มีข้อมูลผู้เล่นในขณะนี้", view=self.view, embed=None)
        else:
            data = player_data.get(selected_value)
            if data:
                embed = discord.Embed(title=f"ข้อมูลของ {selected_value}", color=discord.Color.blurple())
                embed.add_field(name="จำนวนเงิน", value=data['cash'], inline=False)
                embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data['serverName'], inline=False)
                embed.add_field(name="ID", value=data.get('playerId', 'N/A'), inline=False)
                await interaction.response.edit_message(embed=embed, view=self.view)
            else:
                await interaction.response.edit_message(content=f"ไม่พบข้อมูลสำหรับผู้เล่น {selected_value}", view=self.view, embed=None)

async def send_main_message():
    global main_message
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    embed = discord.Embed(title="📊 ข้อมูลผู้เล่น Roblox 📊", description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด หรือดูข้อมูลทั้งหมด", color=discord.Color.dark_theme())
    view = PlayerDropdown()
    if main_message is None:
        main_message = await channel.send(embed=embed, view=view)
    else:
        await main_message.edit(embed=embed, view=view)

    while True:
        await asyncio.sleep(20)
        if main_message:
            view = PlayerDropdown()
            embed = discord.Embed(title="📊 ข้อมูลผู้เล่น Roblox 📊", description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด หรือดูข้อมูลทั้งหมด", color=discord.Color.dark_theme())
            await main_message.edit(embed=embed, view=view)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)

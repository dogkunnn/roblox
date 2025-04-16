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
            self.add_item(PlayerSelect(list(player_data.keys())))

class PlayerSelect(discord.ui.Select):
    def __init__(self, usernames):
        options = [
            discord.SelectOption(label=username, description=f"ดูข้อมูลของ {username}")
            for username in usernames
        ]
        super().__init__(placeholder="เลือกชื่อผู้เล่น", options=options)

    async def callback(self, interaction: discord.Interaction):
        selected_username = self.values[0]
        data = player_data.get(selected_username)
        if data:
            embed = discord.Embed(title=f"ข้อมูลผู้เล่น", color=0xADD8E6)  # Light blue color
            embed.add_field(name="ชื่อผู้เล่น", value=selected_username, inline=False)
            embed.add_field(name="จำนวนเงิน", value=f"💰 {data.get('cash', 'N/A')}", inline=True)
            embed.add_field(name="ผู้เล่นในเซิร์ฟเวอร์", value=f"👤 {data.get('playerCount', 'N/A')}", inline=True)
            embed.add_field(name="เซิร์ฟเวอร์", value=f"🎮 {data.get('serverName', 'N/A')}", inline=False)
            embed.set_footer(text="อัปเดตล่าสุด")
            await interaction.response.edit_message(embed=embed, view=self.view)

async def send_main_message():
    global main_message
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    if main_message is None:
        embed = discord.Embed(title="📊 ข้อมูลผู้เล่น Roblox", description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด", color=0xF0F8FF) # Very light gray/off-white
        view = PlayerDropdown()
        main_message = await channel.send(embed=embed, view=view)

    while True:
        if main_message:
            view = PlayerDropdown()
            embed = discord.Embed(title="📊 ข้อมูลผู้เล่น Roblox", description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด", color=0xF0F8FF) # Very light gray/off-white
            all_players_text = "\n".join(f"- {name}" for name in player_data.keys())
            if all_players_text:
                embed.add_field(name="ทั้งหมด:", value=all_players_text, inline=False)
            embed.set_footer(text=f"อัปเดตล่าสุดเมื่อ: {discord.utils.format_dt(discord.utils.utcnow(), 'R')}")
            try:
                await main_message.edit(embed=embed, view=view)
            except discord.errors.NotFound:
                # Handle the case where the message was deleted
                channel = bot.get_channel(CHANNEL_ID)
                embed = discord.Embed(title="📊 ข้อมูลผู้เล่น Roblox", description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด", color=0xF0F8FF) # Very light gray/off-white
                view = PlayerDropdown()
                main_message = await channel.send(embed=embed, view=view)
            except discord.errors.HTTPException as e:
                print(f"Error editing message: {e}")
        await asyncio.sleep(40)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)

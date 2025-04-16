import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands

# ตั้งค่า Flask และ Discord Bot
app = Flask(__name__)
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

player_data = {}
main_message = None
main_view = None

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
        player_data[username] = data
        print(f"Updated data for {username}: {data}")
    return {"status": "ok", "received": data}


# Discord UI Dropdown
class PlayerSelect(discord.ui.Select):
    def __init__(self):
        options = [
            discord.SelectOption(label=username, description=f"ดูข้อมูลของ {username}")
            for username in player_data
        ]
        super().__init__(placeholder="เลือกชื่อผู้เล่น", options=options)

    async def callback(self, interaction: discord.Interaction):
        selected_username = self.values[0]
        data = player_data.get(selected_username)
        if data:
            embed = discord.Embed(title=f"ข้อมูลของ {selected_username}", color=discord.Color.green())
            embed.add_field(name="จำนวนเงิน", value=data['cash'], inline=False)
            embed.add_field(name="จำนวนผู้เล่นในเซิร์ฟเวอร์", value=str(data['playerCount']), inline=False)
            embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data['serverName'], inline=False)
            await interaction.response.edit_message(embed=embed, view=self.view)

class PlayerDropdown(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)
        self.select_menu = PlayerSelect()
        self.add_item(self.select_menu)

    def update_options(self):
        self.clear_items()
        self.select_menu = PlayerSelect()
        self.add_item(self.select_menu)


async def send_main_message():
    global main_message, main_view
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    embed = discord.Embed(title="ข้อมูลผู้เล่น Roblox", description="เลือกชื่อเพื่อดูรายละเอียด", color=discord.Color.blue())
    main_view = PlayerDropdown()
    main_message = await channel.send(embed=embed, view=main_view)

    while True:
        # อัปเดต dropdown options โดยไม่ส่งข้อความใหม่
        if main_view and main_message:
            main_view.update_options()
            await main_message.edit(view=main_view)
        await asyncio.sleep(10)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)
    

import os
import threading
import asyncio
from flask import Flask, request, jsonify
import discord
from discord.ext import commands

app = Flask(__name__)

DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = 1362080053583937716

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

player_data = {}
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
        player_data[username] = data
        print(f"Updated data for {username}: {data}")
    return {"status": "ok", "received": data}

class PlayerSelect(discord.ui.Select):
    def __init__(self):
        options = [
            discord.SelectOption(label=username, description="คลิกเพื่อดูข้อมูล")
            for username in list(player_data.keys())[:25]  # Discord จำกัดสูงสุด 25
        ] or [discord.SelectOption(label="ไม่มีข้อมูล", value="none", default=True)]
        super().__init__(placeholder="เลือกผู้เล่น", options=options, custom_id="player_select")

    async def callback(self, interaction: discord.Interaction):
        username = self.values[0]
        data = player_data.get(username)
        if not data:
            await interaction.response.send_message("ไม่พบข้อมูลผู้เล่น", ephemeral=True)
            return

        embed = discord.Embed(title=f"ข้อมูลของ {username}", color=discord.Color.green())
        embed.add_field(name="จำนวนเงิน", value=data.get('cash', 'N/A'), inline=False)
        embed.add_field(name="ผู้เล่นในเซิร์ฟ", value=data.get('playerCount', 'N/A'), inline=False)
        embed.add_field(name="ชื่อเซิร์ฟเวอร์", value=data.get('serverName', 'N/A'), inline=False)
        await interaction.response.edit_message(embed=embed, view=self.view)

class PlayerDropdown(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)
        self.update_options()

    def update_options(self):
        self.clear_items()
        self.add_item(PlayerSelect())

async def send_main_message():
    global main_message
    await bot.wait_until_ready()
    channel = bot.get_channel(CHANNEL_ID)

    embed = discord.Embed(
        title="ข้อมูลผู้เล่น Roblox",
        description="เลือกชื่อผู้เล่นเพื่อดูรายละเอียด",
        color=discord.Color.blue()
    )
    view = PlayerDropdown()

    if main_message is None:
        main_message = await channel.send(embed=embed, view=view)

    while True:
        try:
            # แก้ไข dropdown ทุก ๆ 15 วินาที
            embed.description = "อัปเดตล่าสุดแล้ว • คลิกชื่อผู้เล่นเพื่อดูข้อมูล"
            new_view = PlayerDropdown()
            await main_message.edit(embed=embed, view=new_view)
        except Exception as e:
            print("Error updating message:", e)
        await asyncio.sleep(15)

def start_flask():
    app.run(host="0.0.0.0", port=10000)

if __name__ == '__main__':
    threading.Thread(target=start_flask).start()
    bot.loop.create_task(send_main_message())
    bot.run(DISCORD_TOKEN)


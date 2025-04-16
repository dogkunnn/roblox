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
            discord.SelectOption(label=username, description=f"กดเพื่อดูข้อมูล", emoji="🎮")
            for username in player_data
        ]
        super().__init__(
            placeholder="เลือกผู้เล่นจากรายชื่อ...",
            min_values=1,
            max_values=1,
            options=options
        )

    async def callback(self, interaction: discord.Interaction):
        selected_username = self.values[0]
        data = player_data.get(selected_username)
        if data:
            embed = discord.Embed(
                title=f"ข้อมูลของ {selected_username}",
                color=discord.Color.from_rgb(44, 47, 51)  # สีเทาเข้มแบบ Discord
            )
            embed.add_field(name="💰 เงิน", value=f"`{data['cash']}`", inline=True)
            embed.add_field(name="👥 ผู้เล่นในเซิร์ฟ", value=f"`{data['playerCount']}`", inline=True)
            embed.add_field(name="🗺️ เซิร์ฟเวอร์", value=f"`{data['serverName']}`", inline=False)
            embed.set_footer(text="อัปเดตเรียลไทม์ทุก 10 วินาที", icon_url="https://cdn-icons-png.flaticon.com/512/4712/4712039.png")
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

    embed = discord.Embed(
        title="**Roblox Player Monitor**",
        description="เลือกชื่อผู้เล่นด้านล่างเพื่อดูรายละเอียดแบบเรียลไทม์",
        color=discord.Color.from_rgb(54, 57, 63)
    )
    embed.set_footer(text="ระบบอัปเดตอัตโนมัติทุก 10 วินาที")

    main_view = PlayerDropdown()
    main_message = await channel.send(embed=embed, view=main_view)

    while True:
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


package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.4.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = ['freeplay', #if ACHIEVEMENTS_ALLOWED 'awards', #end 'credits', #if !switch 'donate', #end 'options'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		#if mobileC
		addVirtualPad(UP_DOWN, A_B_C);
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://youtube.com/c/NonsenseHumorLOL');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new OptionsState());
								}
							});
						}
					});
				}
			}
			else if (FlxG.keys.justPressed.SEVEN #if mobileC || _virtualpad.buttonC.justPressed #end)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.offset.y = 0;
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
				spr.offset.x = 0.15 * (spr.frameWidth / 2 + 180);
				spr.offset.y = 0.15 * spr.frameHeight;
				FlxG.log.add(spr.frameWidth);
			}
		});
	}
}r.frameWidth);
			}
		});
	}
}687.5,3,0],[49875,2,0],[50062.5,3,0],[50437.5,2,0],[50625,1,0],[50812.5,3,0],[50250,0,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":100},{"sectionNotes":[[51093.75,3,0],[51187.5,3,0],[51000,3,0],[52312.5,0,0],[52218.75,0,0],[51281.25,0,0],[51375,2,0],[51562.5,3,0],[51750,2,0],[51937.5,1,0],[52125,0,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[52687.5,0,0],[52500,1,0],[52875,2,0],[53062.5,3,0],[53812.5,2,0],[53625,2,0],[53250,1,281.25],[53812.5,0,0],[53625,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[54375,2,0],[54187.5,0,0],[54750,0,0],[54843.75,2,0],[54937.5,1,0],[54000,1,0],[55125,2,0],[55312.5,0,0],[54562.5,3,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[55500,2,0],[55687.5,3,0],[55875,2,0],[56062.5,3,0],[56437.5,2,0],[56625,1,0],[56812.5,3,0],[56250,0,"Change Character"]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[57093.75,3,0],[57187.5,3,0],[57562.5,3,0],[57000,3,0],[57750,2,0],[57937.5,1,0],[58125,0,0],[58312.5,0,0],[58218.75,0,0],[57375,2,0],[57281.25,0,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[58687.5,0,0],[58500,1,0],[58875,2,0],[59062.5,3,0],[59812.5,2,0],[59625,2,0],[59250,1,281.25],[59812.5,0,0],[59625,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[60000,3,468.75],[61125,1,656.25],[60562.5,0,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[62437.5,2,468.75],[61875,0,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[63562.5,1,468.75],[63000,0,468.75],[64125,3,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[64687.5,2,468.75],[65625,1,281.25],[65250,0,281.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[66000,3,468.75],[67125,1,656.25],[66562.5,0,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[68437.5,2,468.75],[67875,0,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[69562.5,1,468.75],[69000,0,468.75],[70125,3,468.75]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[70687.5,6,468.75],[71625,5,281.25],[71250,4,281.25],[71625,-1,"Play Animation","hey","dad"],[71967.1875,-1,"Change Character","dad","hankmad"]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[72281.25,1,0],[72375,0,0],[72187.5,3,0],[72000,3,0],[72093.75,2,0],[72468.75,1,187.5],[72750,2,0],[72843.75,3,0],[72937.5,2,0],[73125,1,0],[73312.5,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[73500,2,0],[73593.75,3,0],[73875,2,0],[73968.75,3,0],[74062.5,0,0],[73687.5,0,0],[74250,2,0],[74343.75,3,0],[74437.5,0,0],[74625,1,0],[74812.5,3,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[75281.25,1,0],[75375,0,0],[75187.5,3,0],[75000,3,0],[75093.75,2,0],[75468.75,1,187.5],[75750,2,0],[75843.75,3,0],[75937.5,2,0],[76125,1,0],[76312.5,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[76500,2,0],[76593.75,3,0],[76875,2,0],[76968.75,3,0],[77062.5,0,0],[76687.5,0,0],[77250,2,0],[77343.75,3,0],[77625,1,0],[77812.5,3,0],[77437.5,0,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[78000,1,0],[78375,1,0],[78093.75,3,0],[78187.5,1,0],[78281.25,3,0],[78562.5,2,0],[78750,0,0],[79125,2,281.25],[78937.5,1,93.75],[78656.25,3,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[79500,1,0],[79875,1,0],[79593.75,3,0],[79687.5,1,0],[79781.25,3,0],[80062.5,2,0],[80250,0,0],[80625,2,281.25],[80437.5,1,93.75],[80156.25,3,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[81093.75,3,0],[81281.25,3,0],[81656.25,3,0],[81000,2,0],[81187.5,2,0],[81562.5,0,0],[82125,1,281.25],[81937.5,3,93.75],[81750,0,0],[81375,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[82593.75,3,0],[82781.25,3,0],[83156.25,3,0],[82500,2,0],[82687.5,2,0],[83062.5,0,0],[83625,1,281.25],[83437.5,3,93.75],[83250,0,0],[82875,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[84187.5,1,0],[84281.25,0,0],[84562.5,3,0],[84750,3,0],[84937.5,3,0],[85125,3,0],[85312.5,3,0],[84375,1,0],[84281.25,2,0],[84000,-1,"Add Camera Zoom","0.030","0.06"],[84375,-1,"Add Camera Zoom","0.030","0.06"],[84750,-1,"Add Camera Zoom","0.030","0.06"],[85125,-1,"Add Camera Zoom","0.030","0.06"]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[85781.25,2,0],[85875,3,0],[85687.5,3,0],[86437.5,0,0],[86625,0,0],[86812.5,0,0],[86250,0,0],[86062.5,0,0],[85781.25,0,0],[85500,3,0],[85500,-1,"Add Camera Zoom","0.030","0.06"],[85875,-1,"Add Camera Zoom","0.030","0.06"],[86250,-1,"Add Camera Zoom","0.030","0.06"],[86625,-1,"Add Camera Zoom","0.030","0.06"]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[87562.5,3,0],[87750,3,0],[87937.5,3,0],[88125,3,0],[88312.5,3,0],[87187.5,1,0],[87281.25,0,0],[87375,1,0],[87000,0,0],[87281.25,2,0],[87000,-1,"Add Camera Zoom","0.030","0.06"],[87375,-1,"Add Camera Zoom","0.030","0.06"],[87750,-1,"Add Camera Zoom","0.030","0.06"],[88125,-1,"Add Camera Zoom","0.030","0.06"]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[88875,0,0],[89062.5,0,0],[89062.5,1,0],[89062.5,3,0],[89062.5,2,0],[89250,0,0],[89250,1,0],[89250,3,0],[89250,2,0],[89437.5,1,0],[89437.5,0,0],[89437.5,2,0],[89437.5,3,0],[89625,0,0],[89625,1,0],[89625,2,0],[89625,3,0],[89812.5,1,0],[89812.5,0,0],[89812.5,2,0],[89812.5,3,0],[88500,3,0],[88687.5,0,0],[88781.25,1,0],[88500,-1,"Add Camera Zoom","0.030","0.06"],[88875,-1,"Add Camera Zoom","0.030","0.06"],[89250,-1,"Add Camera Zoom","0.030","0.06"],[89625,-1,"Add Camera Zoom","0.030","0.06"],[89812.5,-1,"Add Camera Zoom","0.030","0.06"]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[90187.5,1,0],[90281.25,0,0],[90562.5,3,0],[90750,3,0],[90937.5,3,0],[91125,3,0],[91312.5,3,0],[90375,1,0],[90281.25,2,0],[90000,-1,"Add Camera Zoom","0.030","0.06"],[90375,-1,"Add Camera Zoom","0.030","0.06"],[90750,-1,"Add Camera Zoom","0.030","0.06"],[91125,-1,"Add Camera Zoom","0.030","0.06"]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[91781.25,2,0],[91875,3,0],[91687.5,3,0],[92437.5,0,0],[92625,0,0],[92812.5,0,0],[92250,0,0],[92062.5,0,0],[91781.25,0,0],[91500,3,0],[91500,-1,"Add Camera Zoom","0.030","0.06"],[91875,-1,"Add Camera Zoom","0.030","0.06"],[92250,-1,"Add Camera Zoom","0.030","0.06"],[92625,-1,"Add Camera Zoom","0.030","0.06"]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[93562.5,3,0],[93750,3,0],[93937.5,3,0],[94125,3,0],[94312.5,3,0],[93187.5,1,0],[93281.25,0,0],[93375,1,0],[93000,0,0],[93281.25,2,0],[93000,-1,"Add Camera Zoom","0.030","0.06"],[93375,-1,"Add Camera Zoom","0.030","0.06"],[93750,-1,"Add Camera Zoom","0.030","0.06"],[94125,-1,"Add Camera Zoom","0.030","0.06"]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[94875,0,0],[95062.5,0,0],[95062.5,1,0],[95062.5,2,0],[95250,1,0],[95250,2,0],[95437.5,1,0],[95437.5,2,0],[95437.5,3,0],[95625,0,0],[95625,1,0],[95625,2,0],[95812.5,1,0],[95812.5,0,0],[95812.5,2,0],[95812.5,3,0],[94500,3,0],[94687.5,0,0],[94781.25,1,0],[94500,-1,"Add Camera Zoom","0.030","0.06"],[94875,-1,"Add Camera Zoom","0.030","0.06"],[95250,-1,"Add Camera Zoom","0.030","0.06"],[95625,-1,"Add Camera Zoom","0.030","0.06"],[95718.75,-1,"Add Camera Zoom","0.030","0.06"],[95812.5,-1,"Add Camera Zoom","0.030","0.06"]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[96187.5,3,0],[96375,2,0],[96000,2,0],[97125,1,281.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[98250,1,656.25],[97500,0,656.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"sectionNotes":[[99000,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[100500,2,0],[100875,3,0],[101250,2,0],[101625,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[102000,0,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[104250,3,656.25],[103500,2,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[105750,0,656.25],[105000,1,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[106500,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[108187.5,3,0],[108375,2,0],[108000,2,0],[109125,1,281.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[110250,1,656.25],[109500,0,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[111000,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[112500,2,0],[112875,3,0],[113250,2,0],[113625,1,0]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[114000,0,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[115500,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[117000,1,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[118500,0,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[120187.5,3,0],[120375,2,0],[120000,2,0],[121125,1,281.25],[120000,5,2906.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[122250,1,656.25],[121500,0,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[123000,2,1406.25],[123000,4,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[124500,6,656.25],[124500,2,0],[124875,3,0],[125250,2,0],[125625,1,0],[125250,4,281.25],[125625,5,281.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[126000,7,1406.25],[126000,0,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[127500,5,1406.25],[127500,2,656.25],[128250,3,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[129750,0,656.25],[129000,1,656.25],[129000,6,2906.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[130500,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":false,"changeBPM":false,"bpm":212},{"sectionNotes":[[132187.5,3,0],[132375,2,0],[132000,2,0],[133125,1,281.25],[132000,5,2906.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[134250,1,656.25],[133500,0,656.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[[135000,4,1406.25],[135000,2,1406.25]],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[136500,6,656.25],[136500,2,0],[136875,3,0],[137250,2,0],[137625,1,0],[137250,4,281.25],[137625,5,281.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[138000,7,1406.25],[138000,0,1406.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[139500,7,1406.25],[139500,2,1406.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[141000,6,2906.25],[141000,1,1406.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[142500,2,1406.25]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[144000,2,0],[144093.75,3,0],[144187.5,2,0],[144281.25,3,0],[144375,2,0],[144468.75,1,0],[144562.5,2,0],[144656.25,1,0],[144750,0,0],[144843.75,2,0],[144937.5,3,0],[145031.25,1,0],[145125,0,0],[145312.5,2,0],[145406.25,3,0],[145218.75,3,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[145500,2,0],[145593.75,3,0],[145687.5,2,0],[145781.25,3,0],[145875,2,0],[145968.75,1,0],[146062.5,2,0],[146156.25,1,0],[146250,0,0],[146343.75,2,0],[146437.5,3,0],[146531.25,1,0],[146625,0,0],[146812.5,2,0],[146906.25,3,0],[146718.75,3,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[147000,0,0],[147093.75,3,0],[147187.5,0,0],[147281.25,3,0],[147468.75,3,0],[147562.5,0,0],[147750,2,0],[147656.25,1,0],[147843.75,1,0],[147937.5,0,0],[148031.25,2,0],[148125,3,0],[148218.75,1,0],[148312.5,0,0],[147375,1,0],[148406.25,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[148500,0,0],[148593.75,3,0],[148687.5,0,0],[148781.25,3,0],[148968.75,3,0],[149062.5,0,0],[149250,2,0],[149156.25,1,0],[149343.75,1,0],[149437.5,0,0],[149531.25,2,0],[149625,3,0],[149718.75,1,0],[149812.5,0,0],[148875,1,0],[149906.25,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[150000,0,0],[150187.5,0,0],[150375,0,0],[150843.75,0,0],[150468.75,0,0],[150562.5,1,0],[151312.5,1,0],[151218.75,3,0],[150750,2,0],[150937.5,2,0],[151125,0,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[151500,0,0],[151687.5,0,0],[151875,0,0],[152343.75,0,0],[151968.75,0,0],[152718.75,3,0],[152812.5,1,0],[152062.5,1,0],[152250,2,0],[152437.5,2,0],[152625,0,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[153000,3,0],[153187.5,3,0],[153375,3,0],[153468.75,3,0],[153843.75,3,0],[153562.5,2,0],[153750,2,0],[153937.5,0,0],[154125,2,0],[154218.75,3,0],[154312.5,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[154500,3,0],[154687.5,3,0],[154875,3,0],[155250,2,0],[155625,2,0],[154968.75,3,0],[155343.75,3,0],[155718.75,3,0],[155812.5,1,0],[155062.5,2,0],[155437.5,0,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[156000,2,0],[156187.5,3,0],[157125,1,0],[157312.5,0,0],[156656.25,3,0],[156937.5,3,0],[156375,0,0],[156750,0,0],[156562.5,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[157500,3,0],[158437.5,3,0],[158625,2,0],[158812.5,0,0],[158062.5,0,0],[158156.25,1,0],[157687.5,1,0],[157875,3,0],[158250,0,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[159000,2,0],[159187.5,3,0],[160125,1,0],[160312.5,0,0],[159656.25,3,0],[159937.5,3,0],[159375,0,0],[159750,0,0],[159562.5,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[160500,3,0],[161437.5,3,0],[161625,2,0],[161812.5,0,0],[161062.5,0,0],[161156.25,1,0],[160687.5,1,0],[160875,3,0],[161250,0,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[162187.5,0,0],[162000,1,0],[162375,1,0],[162562.5,2,0],[162656.25,3,0],[162750,2,0],[162937.5,0,0],[163125,1,0],[163312.5,3,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[164250,1,0],[163500,1,0],[163687.5,0,0],[163875,2,0],[164062.5,3,0],[164156.25,2,0],[164437.5,0,0],[164625,2,0],[164812.5,3,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[165187.5,0,0],[165000,1,0],[165375,1,0],[165562.5,2,0],[165656.25,3,0],[165750,2,0],[165937.5,0,0],[166125,1,0],[166312.5,3,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[[167250,1,0],[166500,1,0],[166687.5,0,0],[166875,2,0],[167062.5,3,0],[167156.25,2,0],[167437.5,0,0],[167625,2,0],[167812.5,1,0]],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":false},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":212,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":212},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"lengthInSteps":16,"typeOfSection":0,"sectionNotes":[],"altAnim":false,"bpm":160,"changeBPM":false,"mustHitSection":true},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"sectionNotes":[],"typeOfSection":0,"lengthInSteps":16,"altAnim":false,"mustHitSection":true,"changeBPM":false,"bpm":160},{"lengthInSteps":16,"altAnim":false,"typeOfSection":0,"sectionNotes":[],"bpm":160,"changeBPM":false,"mustHitSection":true}],"song":"Fresh","needsVoices":true,"sections":0,"stage":"stage","validScore":true,"bpm":160,"speed":3.1}},"sections":0,"stage":"stage","validScore":true,"bpm":160,"speed":3.1}}
var demo_default_hero = "npc_dota_hero_huskar"

function Init()
{
	$.RegisterEventHandler( 'DOTAUIHeroPickerHeroSelected', $( '#SelectHeroContainer' ), SwitchToNewHero );

    var UiDefaults = CustomNetTables.GetTableValue( "game_global", "ui_defaults" );

    if( UiDefaults )
    {
		$( '#FreeSpellsButton' ).SetSelected( UiDefaults["WTFEnabled"] );
		if ( UiDefaults['Cheats_enable'] && UiDefaults['Cheats_enable'] == 1 ) {
			$( '#control' ).style.visibility = "visible"
		} else {
			$( '#control' ).style.visibility = "collapse"
		}
    }
}
Init();

CustomNetTables.SubscribeNetTableListener( "birzha_pick", UpdateHeroes );

function UpdateHeroes(table, key, data ) {
	if (table == "birzha_pick") {
		if (key == "hero_list") {
			RegisterHeroes()
		}
	}
}

function RegisterHeroes()
{
    var hero_list = CustomNetTables.GetTableValue("birzha_pick", "hero_list");
    if (hero_list)
    {
        if (hero_list.str !== null)
        {
            if( $("#HeroBirzhaList").FindChild("StrengthSelector") ) return;


            var AttributePanelSTR = $.CreatePanel("Panel", $("#HeroBirzhaList"), "AttributePanel" );
            AttributePanelSTR.style.borderBrush = "gradient( radial, 50% 50%, 0% 0%, 50% 55%, from( red ), to( #fff0 ) )"
            var AttributePanelStyleSTR = $.CreatePanel("Panel", AttributePanelSTR, "AttributePanelStyle" );
            var AttributePanelIconSTR = $.CreatePanel("Panel", AttributePanelStyleSTR, "AttributePanelIcon" );
            AttributePanelIconSTR.AddClass("StrIcon")
            var AttributePanelLabelSTR = $.CreatePanel("Label", AttributePanelStyleSTR, "AttributePanelLabel" );
            AttributePanelLabelSTR.text = $.Localize("#DOTA_Hero_Selection_STR")
            var str_row = $.CreatePanel("Panel", $("#HeroBirzhaList"), "StrengthSelector" );



            for (var i = 1; i <= hero_list.str_length; i++) 
            {
                var hero_creating = $("#StrengthSelector").FindChild(hero_list.str[i])
                if (hero_creating) { return };
                var panel = $.CreatePanel("Panel", $("#StrengthSelector"), hero_list.str[i] );
                panel.AddClass("hero_select_panel"); 
                var icon = $.CreatePanel("Panel", panel, "image");
                icon.AddClass("hero_select_panel_img");
                icon.style.backgroundImage = 'url("file://{images}/custom_game/cm/heroes_pick/' + hero_list.str[i] + '.png")';
                icon.style.backgroundSize = 'contain';
                SetHero(panel, hero_list.str[i]);
                panel.BLoadLayoutSnippet('HeroCard');
            }
        }

        if (hero_list.ag !== null)
        {
            if( $("#HeroBirzhaList").FindChild("AgilitySelector") ) return;

            var AttributePanelAGI = $.CreatePanel("Panel", $("#HeroBirzhaList"), "AttributePanel" );
            AttributePanelAGI.style.borderBrush = "gradient( radial, 50% 50%, 0% 0%, 50% 55%, from( #08cc0f ), to( #fff0 ) )"
            var AttributePanelStyleAGI = $.CreatePanel("Panel", AttributePanelAGI, "AttributePanelStyle" );
            var AttributePanelIconAGI = $.CreatePanel("Panel", AttributePanelStyleAGI, "AttributePanelIcon" );
            AttributePanelIconAGI.AddClass("AgiIcon")
            var AttributePanelLabelAGI = $.CreatePanel("Label", AttributePanelStyleAGI, "AttributePanelLabel" );
            AttributePanelLabelAGI.text = $.Localize("#DOTA_Hero_Selection_AGI")
            var agi_row = $.CreatePanel("Panel", $("#HeroBirzhaList"), "AgilitySelector" );


            for (var i = 1; i <= hero_list.ag_length; i++) 
            {
                var hero_creating = $("#AgilitySelector").FindChild(hero_list.ag[i])
                if (hero_creating) { return };
                var panel = $.CreatePanel("Panel", $("#AgilitySelector"), hero_list.ag[i] );
                panel.AddClass("hero_select_panel");
                var icon = $.CreatePanel("Panel", panel, "image");
                icon.AddClass("hero_select_panel_img");
                icon.style.backgroundImage = 'url("file://{images}/custom_game/cm/heroes_pick/' + hero_list.ag[i] + '.png")';
                icon.style.backgroundSize = 'contain';
                SetHero(panel, hero_list.ag[i]);
                panel.BLoadLayoutSnippet('HeroCard');
            }
        }

        if (hero_list.int !== null)
        {
            if( $("#HeroBirzhaList").FindChild("IntellectSelector") ) return;
            var AttributePanelINT = $.CreatePanel("Panel", $("#HeroBirzhaList"), "AttributePanel" );
            AttributePanelINT.style.borderBrush = "gradient( radial, 50% 50%, 0% 0%, 50% 55%, from( #08bfcc ), to( #fff0 ) )"
            var AttributePanelStyleINT = $.CreatePanel("Panel", AttributePanelINT, "AttributePanelStyle" );
            var AttributePanelIconINT = $.CreatePanel("Panel", AttributePanelStyleINT, "AttributePanelIcon" );
            AttributePanelIconINT.AddClass("IntIcon")
            var AttributePanelLabelINT = $.CreatePanel("Label", AttributePanelStyleINT, "AttributePanelLabel" );
            AttributePanelLabelINT.text = $.Localize("#DOTA_Hero_Selection_INT")
            var int_row = $.CreatePanel("Panel", $("#HeroBirzhaList"), "IntellectSelector" );

            for (var i = 1; i <= hero_list.int_length; i++) 
            {
                var hero_creating = $("#IntellectSelector").FindChild(hero_list.int[i])
                if (hero_creating) { return };
                var panel = $.CreatePanel("Panel", $("#IntellectSelector"), hero_list.int[i] );
                panel.AddClass("hero_select_panel");
                var icon = $.CreatePanel("Panel", panel, "image");
                icon.AddClass("hero_select_panel_img");
                icon.style.backgroundImage = 'url("file://{images}/custom_game/cm/heroes_pick/' + hero_list.int[i] + '.png")';
                icon.style.backgroundSize = 'contain';
                SetHero(panel, hero_list.int[i]);
                panel.BLoadLayoutSnippet('HeroCard');
            }
        }
    }
}

function SetHero(panel, hero)
{
	panel.SetPanelEvent("onactivate", function() { 
        demo_default_hero = hero
        SetHeroPickerVisible( false );
        $.Msg(hero)
        $("#SpawnHeroName").text = $.Localize("#" + hero)
        $("#HeroPickerImage").style.backgroundImage = 'url("file://{images}/custom_game/hight_hood/heroes/' + hero + '.png")'
        $("#HeroPickerImage").style.backgroundSize = "100%"
    } ); 
}



 
















var bHeroPickerVisible = false;

function ToggleHeroPicker( bMainHero )
{
	RegisterHeroes()
	Game.EmitSound( "UI.Button.Pressed" );

	$( '#SelectHeroContainer' ).SetHasClass( 'PickMainHero', bMainHero );

	SetHeroPickerVisible( !bHeroPickerVisible );
}

function SetHeroPickerVisible( bVisible )
{
	if ( bHeroPickerVisible )
	{
		if ( !bVisible )
		{
			$( '#SelectHeroContainer' ).RemoveClass( 'HeroPickerVisible' );
		}
	}
	else
	{
		if ( bVisible )
		{
			$( '#SelectHeroContainer' ).AddClass( 'HeroPickerVisible' );
		}
	}
	bHeroPickerVisible = bVisible;
}

function SwitchToNewHero( nHeroID )
{
	RegisterHeroes()
	Game.EmitSound( "UI.Button.Pressed" );

	if ( $( '#SelectHeroContainer' ).BHasClass( 'PickMainHero' ) )
	{
		$.DispatchEvent( 'FireCustomGameEvent_Str', 'SelectMainHeroButtonPressed', String( nHeroID ) );
	}
	else
	{
		$.DispatchEvent( 'FireCustomGameEvent_Str', 'SelectSpawnHeroButtonPressed', String( nHeroID ) );
	}

	$( '#SelectHeroContainer' ).RemoveClass( 'PickMainHero' );

	SetHeroPickerVisible( false );
}

function ToggleCategoryVisibility( str )
{
    //$.Msg( "^^^ToggleCategoryVisibility() - " + str )
    $( str ).ToggleClass( 'CollapseCategory' )
}

































function SpawnHero(team)
{
	GameEvents.SendCustomGameEventToServer( "SpawnHeroDemo", {hero_name: demo_default_hero, team:team} );
}


function ToggleInvulnerability()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

    for ( var i = 0; i < numEntities; i++ )
    {
        var entindex = entities[ i ];
        if ( entindex == -1 )
            continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'ToggleInvulnerabilityHero', String( entindex ) );
	}
}

function InvulnerableOn()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

	for ( var i = 0; i < numEntities; i++ )
	{
		var entindex = entities[i];
		if ( entindex == -1 )
			continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'InvulnOnHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function InvulnerableOff()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

	for ( var i = 0; i < numEntities; i++ )
	{
		var entindex = entities[i];
		if ( entindex == -1 )
			continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'InvulnOffHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function LevelUpSelectedHeroes()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

    for ( var i = 0; i < numEntities; i++ )
    {
        var entindex = entities[ i ];
        if ( entindex == -1 )
            continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'LevelUpHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function MaxLevelUpSelectedHeroes()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

    for ( var i = 0; i < numEntities; i++ )
    {
        var entindex = entities[ i ];
        if ( entindex == -1 )
            continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'MaxLevelUpHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function ResetSelectedHeroes()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

	for ( var i = 0; i < numEntities; i++ )
	{
		var entindex = entities[i];
		if ( entindex == -1 )
			continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'ResetHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function ShardSelectedHeroes()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

    for ( var i = 0; i < numEntities; i++ )
    {
        var entindex = entities[ i ];
        if ( entindex == -1 )
            continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'ShardHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function ScepterSelectedHeroes()
{
	var entities = Players.GetSelectedEntities( 0 );

	var numEntities = Object.keys( entities ).length;

    for ( var i = 0; i < numEntities; i++ )
    {
        var entindex = entities[ i ];
        if ( entindex == -1 )
            continue;

		$.DispatchEvent( 'FireCustomGameEvent_Str', 'ScepterHero', String( entindex ) );
	}

	if ( numEntities > 0 )
	{
		Game.EmitSound( "UI.Button.Pressed" );
	}
}

function MouseOverRune( strRuneID, strRuneTooltip )
{
	var runePanel = $( '#' + strRuneID );
	runePanel.StartAnimating();
	$.DispatchEvent( 'UIShowTextTooltip', runePanel, strRuneTooltip );
}

function MouseOutRune( strRuneID )
{
	var runePanel = $( '#' + strRuneID );
	runePanel.StopAnimating();
	$.DispatchEvent( 'UIHideTextTooltip', runePanel );
}

function SlideThumbActivate()
{
	var slideThumb = $.GetContextPanel();
	var bMinimized = slideThumb.BHasClass( 'Minimized' );

	if ( bMinimized )
	{
		Game.EmitSound( "ui_settings_slide_out" );
	}
	else
	{
		Game.EmitSound( "ui_settings_slide_in" );
	}

	slideThumb.ToggleClass( 'Minimized' );
}
#!/usr/bin/env bash

set -e

gitRoot="$(git rev-parse --show-toplevel)"
# gitRoot="$gitRoot/.internals/thumbnails"
cd "$gitRoot/terminal/"

mv ./*_black.png "grey on black/"			|| true
mv ./*_alpha.png "grey on alpha/"			|| true
mv ./*_chromab.png "chromatic aberration/"	|| true
echo

dirs=""
dirs+="grey on black"$'\n'
dirs+="grey on alpha"$'\n'
dirs+="chromatic aberration"$'\n'

xmv() {

	if [[ ! -d "$dest" ]]
	then
		mkdir -p "$dest"
	fi

	echo "$1" | while read -r file
	do
		# if [[ ! -f "$file" && "$file" != *"*"* ]]
		if [[ ! -f "$file" ]]
		then
			# chill if the file is missing
			return
		fi

		# no quotes here so wildcards work
		# file names shouldn't contain spaces here anyway
		mv $file "$dest/" || true
	done
}

while read -r dir
do
	dirFullPath="$gitRoot/terminal/$dir"

	if [[ -z "$dir" ]]
	then
		continue
	elif [[ ! -d "$dirFullPath" ]]
	then
		echo "can't find dir: $dir"
		echo "pwd: $PWD"
		exit 1
	fi

	echo "$dir"
	cd "$dirFullPath"

	mkdir -p little
	mkdir -p big

	rename -f 's/_(black|alpha|chromab)\.png$/.png/g' *.png

	# little
	dest="little/misc"
	xmv acorn_by_svgocean.png
	xmv aperture_science.png
	xmv buer_sigil_lineartboutique.png
	xmv caffeine.png
	xmv cassette.png
	xmv chinese_dragon.png
	xmv circuits_vnpcustoms.png
	xmv corner_knot.png
	xmv crack_1.png
	xmv crack_2.png
	xmv equilateral_triangle_heights.png
	xmv fallout_vault_boy.png
	xmv floppy_disk.png
	xmv github_svgrepo_com.png
	xmv halo_monitor.png
	xmv horizontale_coördinatenstelsel.png
	xmv japanese_crest_ageha_cho.png
	xmv magic_hexagram_sum50.png
	xmv mountain.png
	xmv mushrooms_floral_book_5_redearthandgumtrees.png
	xmv mushrooms_floral_mushroom_4_redearthandgumtrees.png
	xmv mushrooms_floral_mushroom_8_redearthandgumtrees.png
	xmv oxoglutarate_dehydrogenase_zh_cn.png
	xmv painted_heart.png
	xmv pizza_hut*
	xmv raven_animapins.png
	xmv skeleton_of_a_cat_diagram_ver_2.png
	xmv small_knots_1.png
	xmv small_knots_2.png
	xmv small_star.png
	xmv space_invader.png
	xmv tree_curly.png
	xmv tree_w_roots.png
	xmv tree_autumn.png
	xmv tribal_animals_tattoo_designs_y.png
	xmv vegvisir_and_runes_parsarart.png
	xmv 南中_小学校理科.png

	dest="little/castlevania"
	xmv castlevania_glyph_agartha_by_pyderek.png
	xmv castlevania_glyph_dominus_agony_by_pyderek.png
	xmv castlevania_glyph_dominus_anger_by_pyderek.png
	xmv castlevania_glyph_dominus_hatred_by_pyderek.png
	xmv castlevania_silhouette_pngfind.png
	xmv castlevania_glyph_agartha_by_pyderek.png

	dest="little/cosmere"
	xmv cosmere_ghostbloods.png
	xmv cosmere.png
	xmv mistborn_atium.png
	xmv stormlight_glyph_kholin.png
	xmv stormlight_glyph_roshar.png
	xmv stormlight_glyph_thath_justice.png
	xmv stormlight_glyph_truthwatchers.png
	xmv stormlight.png
	xmv stormlight_simple.png
	
	dest="little/elder scrolls"
	xmv elder_scrolls_mages_guild_thisonehaswares.png
	xmv elder_scrolls_necromancy_sigil_thisonehaswares.png
	xmv skyrim.png

	dest="little/moons"
	xmv esoteric_moon_artstudiodesignsvg.png
	xmv moon_1.png
	xmv moon_2.png
	xmv moon_buds_artstudiodesignsvg.png
	xmv moon_crystals_artstudiodesignsvg.png

	dest="little/full metal alchemist"
	xmv full_metal_alchemist_blood_seal_rosedesignestudio.png
	xmv full_metal_alchemist_flamel.png
	xmv full_metal_alchemist_ouroboros.png

	dest="little/game icons dot net"
	xmv game_icons_dot_net_aquarium.png
	xmv game_icons_dot_net_beveled_star.png
	xmv game_icons_dot_net_boba.png
	xmv game_icons_dot_net_companion_cube_border.png
	xmv game_icons_dot_net_hobbit_door.png
	xmv game_icons_dot_net_power_button.png
	xmv game_icons_dot_net_processor.png
	xmv game_icons_dot_net_schrodingers_cat_alive.png
	xmv game_icons_dot_net_shuriken.png
	xmv game_icons_dot_net_wanted_reward.png
	xmv game_icons_dot_net_warlord_helmet.png
	xmv game_icons_dot_net_winged_sword.png

	dest="little/language"
	xmv happy_birthday.png

	dest="little/mario"
	xmv mario_bob_omb.png
	xmv mario_mushroom.png
	xmv mario_star.png
	xmv shy_guy.png
	xmv pixel_mario_3_item_block.png
	xmv pixel_mario_3_map_tile.png

	dest="little/nintendo"
	xmv *metroid*
	xmv *nintendo*
	xmv pokeball.png
	xmv samus_helm.png
	xmv smash_ball.png

	dest="little/tolkien"
	xmv one_ring_inscription_ring_a_ling.png
	xmv tolkien_monogram.png
	xmv tolkien*.png

	dest="little/star trek"
	xmv star_trek_klingon_symbol.png
	xmv star_trek_starfleet_insignia.png

	dest="little/tmnt"
	xmv tmnt_back_01_leonardo_by_juliefoohandmade.png
	xmv tmnt_back_02_donatello_by_juliefoohandmade.png
	xmv tmnt_back_03_raphael_by_juliefoohandmade.png
	xmv tmnt_back_04_michelangelo_by_juliefoohandmade.png
	xmv tmnt_japanese_crest_mitumori_kikkou_ni_hanabishi.png
	xmv tmnt_reading_pngwing.png
	xmv tmnt_splinter_clan.png
	xmv tmnt_svgrepo_com.png

	dest="little/the legend of zelda"
	xmv triforce_outline.png
	xmv triforce_simple.png
	xmv triforce_splot.png
	xmv triforce_stabby_wingaling.png
	xmv triforce_wingaling.png
	xmv zelda_botw_sheikah_eye.png
	xmv zelda_botw_stabby_z.png
	xmv zelda_hylian_shield.png

	dest="little/ubuntu"
	xmv ubuntu*.png
	xmv 23_10*.png
	xmv 24_04*.png
	xmv 24_10*.png

	# big
	dest="big/magic circles/bayonetta"
	xmv magic_circle_bayonetta_entrance_to_muspelheim_by_lcl_simon.png
	xmv magic_circle_bayonetta_inferno_umbra_witch_seal_by_lcl_simon.png
	xmv magic_circle_bayonetta_moon_of_mahaa_kalaa_by_lcl_simon.png

	dest="big/magic circles/full metal alchemist"
	xmv magic_circle_full_metal_alchemist*

	dest="big/magic circles/misc"
	xmv magic_circle_*

	dest="big/mandalas"
	xmv mandala*

	dest="big/maps"
	xmv new_york_city_subway_map.png
	xmv tehran_metro_map_v1_0.png

	dest="big/stargate"
	xmv stargate_milkyway.png
	xmv stargate_pegasus.png

	dest="big/the legend of zelda"
	xmv twlight_portal_by_ohcooldesigns.png
	xmv zelda_collection_02_arts_and_artifacts_by_japatonic.png
	xmv zelda_collection_03_encylopedia_by_japatonic.png
	xmv zelda_skyward_sword_gate_of_time_by_tamalesyatole.png
	xmv zelda_totk_ouroboros.png

	dest="big/misc"
	xmv tree_of_life_svg.png
	xmv 20_ponted_cross_graph.png
	xmv circle_squares.png
	xmv compass_rose_cantino.png
	xmv maze.png

done < <(echo "$dirs")

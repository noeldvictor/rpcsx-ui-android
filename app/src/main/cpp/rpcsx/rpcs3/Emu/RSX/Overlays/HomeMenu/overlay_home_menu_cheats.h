#pragma once

#include "overlay_home_menu_page.h"
#include "util/bin_patch.h"

#include <string>
#include <vector>

namespace rsx
{
	namespace overlays
	{
		struct home_menu_cheats : public home_menu_page
		{
		public:
			home_menu_cheats(s16 x, s16 y, u16 width, u16 height, bool use_separators, home_menu_page* parent);

		private:
			struct cheat_match
			{
				std::string hash;
				std::string description;
				std::string title;
				std::string serial;
				std::string app_version;
			};

			static patch_engine::patch_map load_current_game_patches();
			static std::vector<cheat_match> collect_matches(const patch_engine::patch_map& patches);
			static const patch_engine::patch_config_values* find_config_values(const patch_engine::patch_map& patches, const cheat_match& match);
			static patch_engine::patch_config_values* find_config_values(patch_engine::patch_map& patches, const cheat_match& match);

			bool is_enabled(const cheat_match& match) const;
			bool set_enabled(const cheat_match& match, bool enabled);

			patch_engine::patch_map m_patches;
		};
	} // namespace overlays
} // namespace rsx

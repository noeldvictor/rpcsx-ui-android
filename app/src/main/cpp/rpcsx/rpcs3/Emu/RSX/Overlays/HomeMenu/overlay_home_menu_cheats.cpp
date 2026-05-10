#include "stdafx.h"
#include "overlay_home_menu_cheats.h"
#include "Emu/System.h"
#include "Emu/localized_string.h"

namespace rsx
{
	namespace overlays
	{
		namespace
		{
			template <typename Map>
			std::string select_exact_or_all(const Map& map, const std::string& exact)
			{
				if (map.contains(exact))
				{
					return exact;
				}

				if (map.contains(patch_key::all))
				{
					return patch_key::all;
				}

				return {};
			}
		}

		patch_engine::patch_map home_menu_cheats::load_current_game_patches()
		{
			patch_engine::patch_map patches;

			patch_engine::load(patches, patch_engine::get_patches_path() + "patch.yml");
			patch_engine::load(patches, patch_engine::get_imported_patch_path());

			if (const std::string title_id = Emu.GetTitleID(); !title_id.empty())
			{
				patch_engine::load(patches, fmt::format("%s%s_patch.yml", patch_engine::get_patches_path(), title_id));
			}

			return patches;
		}

		std::vector<home_menu_cheats::cheat_match> home_menu_cheats::collect_matches(const patch_engine::patch_map& patches)
		{
			std::vector<cheat_match> matches;
			const std::string serial = Emu.GetTitleID();
			const std::string app_version = Emu.GetAppVersion();

			if (serial.empty())
			{
				return matches;
			}

			for (const auto& [hash, container] : patches)
			{
				for (const auto& [description, patch] : container.patch_info_map)
				{
					for (const auto& [title, serials] : patch.titles)
					{
						const std::string found_serial = select_exact_or_all(serials, serial);

						if (found_serial.empty())
						{
							continue;
						}

						const patch_engine::patch_app_versions& app_versions = ::at32(serials, found_serial);
						const std::string found_app_version = select_exact_or_all(app_versions, app_version);

						if (found_app_version.empty())
						{
							continue;
						}

						matches.push_back({hash, description, title, found_serial, found_app_version});
						break;
					}
				}
			}

			std::sort(matches.begin(), matches.end(), [](const cheat_match& lhs, const cheat_match& rhs)
				{
					return lhs.description < rhs.description;
				});

			return matches;
		}

		const patch_engine::patch_config_values* home_menu_cheats::find_config_values(const patch_engine::patch_map& patches, const cheat_match& match)
		{
			const auto hash_it = patches.find(match.hash);
			if (hash_it == patches.cend())
			{
				return nullptr;
			}

			const auto patch_it = hash_it->second.patch_info_map.find(match.description);
			if (patch_it == hash_it->second.patch_info_map.cend())
			{
				return nullptr;
			}

			const auto title_it = patch_it->second.titles.find(match.title);
			if (title_it == patch_it->second.titles.cend())
			{
				return nullptr;
			}

			const auto serial_it = title_it->second.find(match.serial);
			if (serial_it == title_it->second.cend())
			{
				return nullptr;
			}

			const auto version_it = serial_it->second.find(match.app_version);
			if (version_it == serial_it->second.cend())
			{
				return nullptr;
			}

			return &version_it->second;
		}

		patch_engine::patch_config_values* home_menu_cheats::find_config_values(patch_engine::patch_map& patches, const cheat_match& match)
		{
			auto hash_it = patches.find(match.hash);
			if (hash_it == patches.end())
			{
				return nullptr;
			}

			auto patch_it = hash_it->second.patch_info_map.find(match.description);
			if (patch_it == hash_it->second.patch_info_map.end())
			{
				return nullptr;
			}

			auto title_it = patch_it->second.titles.find(match.title);
			if (title_it == patch_it->second.titles.end())
			{
				return nullptr;
			}

			auto serial_it = title_it->second.find(match.serial);
			if (serial_it == title_it->second.end())
			{
				return nullptr;
			}

			auto version_it = serial_it->second.find(match.app_version);
			if (version_it == serial_it->second.end())
			{
				return nullptr;
			}

			return &version_it->second;
		}

		bool home_menu_cheats::is_enabled(const cheat_match& match) const
		{
			if (const patch_engine::patch_config_values* values = find_config_values(m_patches, match))
			{
				return values->enabled;
			}

			return false;
		}

		bool home_menu_cheats::set_enabled(const cheat_match& match, bool enabled)
		{
			if (patch_engine::patch_config_values* values = find_config_values(m_patches, match))
			{
				values->enabled = enabled;
				patch_engine::save_config(m_patches);
				return true;
			}

			return false;
		}

		home_menu_cheats::home_menu_cheats(s16 x, s16 y, u16 width, u16 height, bool use_separators, home_menu_page* parent)
			: home_menu_page(x, y, width, height, use_separators, parent, get_localized_string(localized_string_id::HOME_MENU_CHEATS))
		{
			m_patches = load_current_game_patches();
			const std::vector<cheat_match> matches = collect_matches(m_patches);

			if (matches.empty())
			{
				std::unique_ptr<overlay_element> empty = std::make_unique<home_menu_entry>(get_localized_string(localized_string_id::HOME_MENU_NO_CHEATS));
				add_item(empty, [](pad_button) -> page_navigation
					{
						return page_navigation::stay;
					});
			}
			else
			{
				for (const cheat_match& match : matches)
				{
					std::unique_ptr<overlay_element> cheat = std::make_unique<home_menu_toggle_entry>(match.description, [this, match]()
						{
							return is_enabled(match);
						});

					add_item(cheat, [this, match](pad_button btn) -> page_navigation
						{
							if (btn != pad_button::cross)
								return page_navigation::stay;

							const bool enabled = !is_enabled(match);
							if (set_enabled(match, enabled))
							{
								rsx_log.notice("User toggled cheat '%s' to %d", match.description, enabled);
								refresh();
								show_dialog(get_localized_string(localized_string_id::HOME_MENU_CHEAT_RESTART_REQUIRED));
							}

							return page_navigation::stay;
						});
				}
			}

			apply_layout();
		}
	} // namespace overlays
} // namespace rsx

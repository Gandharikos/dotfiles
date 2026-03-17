{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) palette slug;
  dir = "Library/Rime";
  inherit (lib.my) toHex;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    # FIXME: not working anyway
    home.file."${dir}/squirrel.custom.yaml".text = ''
      patch:
        style/color_scheme: tokyonight-day
        style/color_scheme_dark: ${slug}
        preset_color_schemes:
          ${slug}:
            name: ${slug}
            font_face: ""                   # 字体及大小
            font_point: 18
            label_font_face: "Helvetica"    # 序号字体及大小
            label_font_point: 12
            comment_font_face: "Helvetica"  # 注字体及大小
            comment_font_point: 16
            # candidate_list_layout: stacked        # 候选项排列方向 stacked(默认) | linear
            # text_orientation: horizontal          # 文字排列方向 horizontal(默认) | vertical
            inline_preedit: true                    # 键入码（拼音）是否显示在键入位置 true | false
            inline_candidate: false                 # 候选项（词句）是否显示在键入位置 true | false
            translucency: false                     # 磨砂： true | false
            mutual_exclusive: false                 # 色不叠加： true | false
            border_height: 0                        # 外边框 高
            border_width: 0                         # 外边框 宽
            corner_radius: 10                       # 外边框 圆角半径
            hilited_corner_radius: 0                # 选中框 圆角半径
            surrounding_extra_expansion: 0          # 候选项背景相对大小？
            shadow_size: 0                          # 阴影大小
            line_spacing: 5                         # 行间距
            base_offset: 0                          # 字基高
            alpha: 1                                # 透明度，0~1
            spacing: 10                             # 拼音与候选项之间的距离 （inline_preedit: false）
            color_space: srgb                       # 色彩空间： srgb | display_p3
            back_color: ${toHex palette.bg_popup}                    # 底色
            hilited_candidate_back_color: ${toHex palette.bg_visual}   # 选中底色
            label_color: ${toHex palette.fg_float}                   # 序号颜色
            hilited_candidate_label_color: ${toHex palette.fg_dark} # 选中序号颜色
            candidate_text_color: ${toHex palette.blue}          # 文字颜色
            hilited_candidate_text_color: ${toHex palette.magenta2}  # 选中文字颜色
            comment_text_color: ${toHex palette.comment}            # 注颜色
            hilited_comment_text_color: ${toHex palette.comment}    # 选中注颜色
            text_color: ${toHex palette.blue}                    # 拼音颜色 （inline_preedit: false）
            hilited_text_color: ${toHex palette.orange}            # 选中拼音颜色 （inline_preedit: false）
            # candidate_back_color:                 # 候选项底色
            # preedit_back_color:                   # 拼音底色 （inline_preedit: false）
            # hilited_back_color:                   # 选中拼音底色 （inline_preedit: false）
            # border_color:                         # 外边框颜色
          tokyonight-day:
            name: tokyonight-day
            font_face: ""                   # 字体及大小
            font_point: 18
            label_font_face: "Helvetica"    # 序号字体及大小
            label_font_point: 12
            comment_font_face: "Helvetica"  # 注字体及大小
            comment_font_point: 16
            # candidate_list_layout: stacked        # 候选项排列方向 stacked(默认) | linear
            # text_orientation: horizontal          # 文字排列方向 horizontal(默认) | vertical
            inline_preedit: true                    # 键入码（拼音）是否显示在键入位置 true | false
            inline_candidate: false                 # 候选项（词句）是否显示在键入位置 true | false
            translucency: false                     # 磨砂： true | false
            mutual_exclusive: false                 # 色不叠加： true | false
            border_height: 0                        # 外边框 高
            border_width: 0                         # 外边框 宽
            corner_radius: 10                       # 外边框 圆角半径
            hilited_corner_radius: 0                # 选中框 圆角半径
            surrounding_extra_expansion: 0          # 候选项背景相对大小？
            shadow_size: 0                          # 阴影大小
            line_spacing: 5                         # 行间距
            base_offset: 0                          # 字基高
            alpha: 1                                # 透明度，0~1
            spacing: 10                             # 拼音与候选项之间的距离 （inline_preedit: false）
            color_space: srgb                       # 色彩空间： srgb | display_p3
            back_color: 0xd0d5e3                    # 底色
            hilited_candidate_back_color: 0xb7c1e3   # 选中底色
            label_color: 0x3760bf                   # 序号颜色
            hilited_candidate_label_color: 0x6172b0 # 选中序号颜色
            candidate_text_color: 0x2e7de9         # 文字颜色
            hilited_candidate_text_color: 0xd20065  # 选中文字颜色
            comment_text_color: 0x848cb5            # 注颜色
            hilited_comment_text_color: 0x848cb5    # 选中注颜色
            text_color: 0x2e7de9                    # 拼音颜色 （inline_preedit: false）
            hilited_text_color: 0xb15c00           # 选中拼音颜色 （inline_preedit: false）
            # candidate_back_color:                 # 候选项底色
            # preedit_back_color:                   # 拼音底色 （inline_preedit: false）
            # hilited_back_color:                   # 选中拼音底色 （inline_preedit: false）
            # border_color:                         # 外边框颜色
    '';
  };
}

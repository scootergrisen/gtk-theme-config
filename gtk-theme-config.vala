using Gtk;

class ThemeConfigWindow : ApplicationWindow {
	Label selectbg_label;
	Label selectfg_label;

	ColorButton selectbg_button;
	ColorButton selectfg_button;
	ColorButton panelbg_button;
	ColorButton panelfg_button;
	ColorButton menubg_button;
	ColorButton menufg_button;

	Switch select_switch;
	Switch panel_switch;
	Switch menu_switch;

	Button revert_button;
	Button apply_button;

	Gdk.RGBA color_rgb;

	File config_dir;
	File home_dir;

	File gtk3_config_file;
	File gtk2_config_file;

	File theme_path;

	string color_hex;

	string color_scheme;

	string selectbg_value;
	string selectfg_value;
	string panelbg_value;
	string panelfg_value;
	string menubg_value;
	string menufg_value;

	internal ThemeConfigWindow (ThemeConfigApp app) {
		Object (application: app, title: "Configure GTK theme");

		// Set window properties
		this.window_position = WindowPosition.CENTER;
		this.resizable = false;
		this.border_width = 10;

		// Set window icon
		try {
			this.icon = IconTheme.get_default ().load_icon ("gtk-theme-config", 48, 0);
		} catch (Error e) {
			stderr.printf ("Could not load application icon: %s\n", e.message);
		}

		// Methods
		create_widgets ();
		connect_signals ();
	}

	void set_values () {

		// Set default values
		selectbg_value = "#398ee7";
		selectfg_value = "#eeeeee";
		panelbg_value = "#cccccc";
		panelfg_value = "#333333";
		menubg_value = "#eeeeee";
		menufg_value = "#333333";

		select_switch.set_active (false);
		panel_switch.set_active (false);
		menu_switch.set_active (false);

		// Read the current values
		var settings = new GLib.Settings ("org.gnome.desktop.interface");
		var color_scheme = settings.get_string ("gtk-color-scheme");
		var theme_name = settings.get_string ("gtk-theme");

		// Set paths of config files
		config_dir = File.new_for_path (Environment.get_user_config_dir ());
		home_dir = File.new_for_path (Environment.get_home_dir ());

		gtk3_config_file = config_dir.get_child ("gtk-3.0").get_child ("gtk.css");

		gtk2_config_file = home_dir.get_child (".gtkrc-2.0");

		// Create path if doesn't exist
		if (!gtk3_config_file.get_parent().query_exists ()) {
			try {
				gtk3_config_file.get_parent().make_directory_with_parents(null);
			} catch (Error e) {
				stderr.printf ("Could not create parent directory: %s\n", e.message);
			}
		}

		// Detect current theme path
		if (gtk3_config_file.query_exists ()) {
			theme_path = gtk3_config_file;
		} else if (home_dir.get_child (".themes/%s/gtk-3.0/gtk-main.css".printf (theme_name)).query_exists ()) {
			theme_path = home_dir.get_child (".themes/%s/gtk-3.0/gtk-main.css".printf (theme_name));
		} else if (home_dir.get_child (".themes/%s/gtk-3.0/gtk.css".printf (theme_name)).query_exists ()) {
			theme_path = home_dir.get_child (".themes/%s/gtk-3.0/gtk.css".printf (theme_name));
		} else if (File.parse_name ("/usr/share/themes/%s/gtk-3.0/gtk-main.css".printf (theme_name)).query_exists ()) {
			theme_path = File.parse_name ("/usr/share/themes/%s/gtk-3.0/gtk-main.css".printf (theme_name));
		} else if (File.parse_name ("/usr/share/themes/%s/gtk-3.0/gtk.css".printf (theme_name)).query_exists ()) {
			theme_path = File.parse_name ("/usr/share/themes/%s/gtk-3.0/gtk.css".printf (theme_name));
		}

		// Read the current theme file
		try {
			var dis = new DataInputStream (theme_path.read ());
			string line;
			while ((line = dis.read_line (null)) != null) {
				if ("@define-color selected_bg_color" in line) {
					selectbg_value = line.substring (32, line.length-33);
					if ("@" in selectbg_value) {
						selectbg_value = "#398ee7";
					}
				}
				if ("@define-color selected_fg_color" in line) {
					selectfg_value = line.substring (32, line.length-33);
					if ("@" in selectfg_value) {
						selectfg_value = "#eeeeee";
					}
				}
				if ("@define-color panel_bg_color" in line) {
					panelbg_value = line.substring (29, line.length-30);
					if ("@" in panelbg_value) {
						panelbg_value = "#cccccc";
					}
				}
				if ("@define-color panel_fg_color" in line) {
					panelfg_value = line.substring (29, line.length-30);
					if ("@" in panelfg_value) {
						panelfg_value = "#333333";
					}
				}
				if ("@define-color menu_bg_color" in line) {
					menubg_value = line.substring (28, line.length-29);
					if ("@" in menubg_value) {
						menubg_value = "#eeeeee";
					}
				}
				if ("@define-color menu_fg_color" in line) {
					menufg_value = line.substring (28, line.length-29);
					if ("@" in menufg_value) {
						menufg_value = "#333333";
					}
				}
				if ("/* select-on */" in line) {
					select_switch.set_active (true);
				}
				if ("/* panel-on */" in line) {
					panel_switch.set_active (true);
				}
				if ("/* menu-on */" in line) {
					menu_switch.set_active (true);
				}
			}
		} catch (Error e) {
			stderr.printf ("Could not read user theme: %s\n", e.message);
		}

		// Read the current color scheme
		if (";" in color_scheme) {
			string[] parts = color_scheme.split_set(";");
			if ("selected_bg_color:#" in parts[0] && "selected_fg_color:#" in parts[1]) {
				selectbg_value = parts[0].substring (18, parts[0].length-18);
				selectfg_value = parts[1].substring (18, parts[1].length-18);
				select_switch.set_active (true);
			}
		}

		// Set colors
		Gdk.RGBA color = Gdk.RGBA ();
		color.parse (selectbg_value);
		selectbg_button.set_rgba (color);
		color.parse (selectfg_value);
		selectfg_button.set_rgba (color);
		color.parse (panelbg_value);
		panelbg_button.set_rgba (color);
		color.parse (panelfg_value);
		panelfg_button.set_rgba (color);
		color.parse (menubg_value);
		menubg_button.set_rgba (color);
		color.parse (menufg_value);
		menufg_button.set_rgba (color);

		if (home_dir.get_child (".themes/%s/gtk-3.0/gtk.gresource".printf (theme_name)).query_exists () || File.parse_name ("/usr/share/themes/%s/gtk-3.0/gtk.gresource".printf (theme_name)).query_exists ()) {
			selectbg_label.set_sensitive (false);
			selectfg_label.set_sensitive (false);
			selectbg_button.set_sensitive (false);
			selectfg_button.set_sensitive (false);
			select_switch.set_sensitive (false);
		}

		apply_button.set_sensitive (false);
	}

	void create_widgets () {
		// Create and setup widgets
		var select_heading = new Label.with_mnemonic ("_<b>Custom selection colors</b>");
		select_heading.set_use_markup (true);
		select_heading.set_halign (Align.START);
		var panel_heading = new Label.with_mnemonic ("_<b>Custom panel colors</b>");
		panel_heading.set_use_markup (true);
		panel_heading.set_halign (Align.START);
		var menu_heading = new Label.with_mnemonic ("_<b>Custom menu colors</b>");
		menu_heading.set_use_markup (true);
		menu_heading.set_halign (Align.START);

		selectbg_label = new Label.with_mnemonic ("_Selection background");
		selectbg_label.set_halign (Align.START);
		selectfg_label = new Label.with_mnemonic ("_Selection text");
		selectfg_label.set_halign (Align.START);
		var panelbg_label = new Label.with_mnemonic ("_Panel background");
		panelbg_label.set_halign (Align.START);
		var panelfg_label = new Label.with_mnemonic ("_Panel text");
		panelfg_label.set_halign (Align.START);
		var menubg_label = new Label.with_mnemonic ("_Menu background");
		menubg_label.set_halign (Align.START);
		var menufg_label = new Label.with_mnemonic ("_Menu text");
		menufg_label.set_halign (Align.START);

		selectbg_button = new ColorButton ();
		selectfg_button = new ColorButton ();
		panelbg_button = new ColorButton ();
		panelfg_button = new ColorButton ();
		menubg_button = new ColorButton ();
		menufg_button = new ColorButton ();

		select_switch = new Switch ();
		select_switch.set_halign (Align.END);
		panel_switch = new Switch ();
		panel_switch.set_halign (Align.END);
		menu_switch = new Switch ();
		menu_switch.set_halign (Align.END);

		revert_button = new Button.from_stock(Stock.REVERT_TO_SAVED);
		apply_button = new Button.from_stock (Stock.APPLY);

		// Buttons
		var buttons = new ButtonBox (Orientation.HORIZONTAL);
		buttons.set_layout (ButtonBoxStyle.EDGE);
		buttons.add (revert_button);
		buttons.add (apply_button);

		// Layout widgets
		var grid = new Grid ();
		grid.set_column_homogeneous (true);
		grid.set_row_homogeneous (true);
		grid.set_column_spacing (5);
		grid.set_row_spacing (5);
		grid.attach (select_heading, 0, 0, 1, 1);
		grid.attach_next_to (select_switch, select_heading, PositionType.RIGHT, 1, 1);
		grid.attach (selectbg_label, 0, 1, 1, 1);
		grid.attach_next_to (selectbg_button, selectbg_label, PositionType.RIGHT, 1, 1);
		grid.attach (selectfg_label, 0, 2, 1, 1);
		grid.attach_next_to (selectfg_button, selectfg_label, PositionType.RIGHT, 1, 1);
		grid.attach (panel_heading, 0, 3, 1, 1);
		grid.attach_next_to (panel_switch, panel_heading, PositionType.RIGHT, 1, 1);
		grid.attach (panelbg_label, 0, 4, 1, 1);
		grid.attach_next_to (panelbg_button, panelbg_label, PositionType.RIGHT, 1, 1);
		grid.attach (panelfg_label, 0, 5, 1, 1);
		grid.attach_next_to (panelfg_button, panelfg_label, PositionType.RIGHT, 1, 1);
		grid.attach (menu_heading, 0, 6, 1, 1);
		grid.attach_next_to (menu_switch, menu_heading, PositionType.RIGHT, 1, 1);
		grid.attach (menubg_label, 0, 7, 1, 1);
		grid.attach_next_to (menubg_button, menubg_label, PositionType.RIGHT, 1, 1);
		grid.attach (menufg_label, 0, 8, 1, 1);
		grid.attach_next_to (menufg_button, menufg_label, PositionType.RIGHT, 1, 1);
		grid.attach (buttons, 0, 9, 2, 1);

		this.add (grid);

		set_values ();
	}

	void connect_signals () {
		selectbg_button.color_set.connect (() => {
			on_selectbg_color_set ();
			apply_button.set_sensitive (true);
		});
		selectfg_button.color_set.connect (() => {
			on_selectfg_color_set ();
			apply_button.set_sensitive (true);
		});
		panelbg_button.color_set.connect (() => {
			on_panelbg_color_set ();
			apply_button.set_sensitive (true);
		});
		panelfg_button.color_set.connect (() => {
			on_panelfg_color_set ();
			apply_button.set_sensitive (true);
		});
		menubg_button.color_set.connect (() => {
			on_menubg_color_set ();
			apply_button.set_sensitive (true);
		});
		menufg_button.color_set.connect (() => {
			on_menufg_color_set ();
			apply_button.set_sensitive (true);
		});
		select_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		revert_button.clicked.connect (() => {
			on_config_reset ();
			revert_button.set_sensitive (false);
		});
		apply_button.clicked.connect (() => {
			on_config_set ();
			apply_button.set_sensitive (false);
			revert_button.set_sensitive (true);
		});
	}

	void rgb_to_hex () {
		int r = (int)Math.round (color_rgb.red * 255);
		int g = (int)Math.round (color_rgb.green * 255);
		int b = (int)Math.round (color_rgb.blue * 255);

		color_hex = "#%02x%02x%02x".printf (r, g, b);
	}

	void on_selectbg_color_set () {
		color_rgb =  selectbg_button.get_rgba ();
		rgb_to_hex ();
		selectbg_value = color_hex;
	}

	void on_selectfg_color_set () {
		color_rgb =  selectfg_button.get_rgba ();
		rgb_to_hex ();
		selectfg_value = color_hex;
	}

	void on_panelbg_color_set () {
		color_rgb =  panelbg_button.get_rgba ();
		rgb_to_hex ();
		panelbg_value = color_hex;
	}

	void on_panelfg_color_set () {
		color_rgb =  panelfg_button.get_rgba ();
		rgb_to_hex ();
		panelfg_value = color_hex;
	}

	void on_menubg_color_set () {
		color_rgb =  menubg_button.get_rgba ();
		rgb_to_hex ();
		menubg_value = color_hex;
	}

	void on_menufg_color_set () {
		color_rgb =  menufg_button.get_rgba ();
		rgb_to_hex ();
		menufg_value = color_hex;
	}

	void on_config_set () {
		set_color_scheme ();
		write_config ();
		notify_change ();
	}

	void on_config_reset () {
		reset_color_scheme ();
		reset_config ();
		set_values ();
		notify_change ();
	}

	void set_color_scheme () {
		// Determine color scheme
		if (select_switch.get_active()) {
			color_scheme = "\"selected_bg_color:%s;selected_fg_color:%s;\"".printf (selectbg_value, selectfg_value);
		} else {
			color_scheme = "\"\"";
		}

		// Set color scheme
		try {
			Process.spawn_command_line_sync ("gsettings set org.gnome.desktop.interface gtk-color-scheme %s".printf (color_scheme));
		} catch (Error e) {
			stderr.printf ("Could not set color scheme for gtk3: %s\n", e.message);
		}
		try {
			Process.spawn_command_line_sync ("gconftool-2 -s /desktop/gnome/interface/gtk_color_scheme -t string %s".printf (color_scheme));
		} catch (Error e) {
			stderr.printf ("Could not set color scheme for gtk2: %s\n", e.message);
		}
		try {
			Process.spawn_command_line_sync ("xfconf-query -n -c xsettings -p /Gtk/ColorScheme -t string -s %s".printf (color_scheme));
		} catch (Error e) {
			stderr.printf ("Could not set color scheme for xfce: %s\n", e.message);
		}
	}

	void reset_color_scheme () {
		try {
			Process.spawn_command_line_sync ("gsettings reset org.gnome.desktop.interface gtk-color-scheme");
		} catch (Error e) {
			stderr.printf ("Could not reset color scheme for gtk3: %s\n", e.message);
		}
		try {
			Process.spawn_command_line_sync ("gconftool-2 -u /desktop/gnome/interface/gtk_color_scheme");
		} catch (Error e) {
			stderr.printf ("Could not reset color scheme for gtk2: %s\n", e.message);
		}
		try {
			Process.spawn_command_line_sync ("xfconf-query -c xsettings -p /Gtk/ColorScheme -r");
		} catch (Error e) {
			stderr.printf ("Could not reset color scheme for xfce: %s\n", e.message);
		}
	}
			
	void reset_config () {
		try {
			if (gtk3_config_file.query_exists ()) {
				gtk3_config_file.delete ();
			}
		} catch (Error e) {
			stderr.printf ("Could not delete previous gtk3 configuration: %s\n", e.message);
		}
		try {
			if (gtk2_config_file.query_exists ()) {
				gtk2_config_file.delete ();
			}
		} catch (Error e) {
			stderr.printf ("Could not delete previous gtk2 configuration: %s\n", e.message);
		}
	}

	void write_config () {
		
		// Determine states
		string select_state1;
		string select_state2;
		string panel_state1;
		string panel_state2;
		string menu_state1;
		string menu_state2;

		string panel_gtk2;
		string menu_gtk2;

		if (select_switch.get_active()) {
			select_state1 = "/* select-on */";
			select_state2 = "/* select-on */";
		} else {
			select_state1 = "/* select-off";
			select_state2 = "select-off */";
		}
		if (panel_switch.get_active()) {
			panel_state1 = "/* panel-on */";
			panel_state2 = "/* panel-on */";
			panel_gtk2 = "style\"gtk-theme-config-panel\"{\nbg[NORMAL]=\"%s\"\nbg[PRELIGHT]=shade(1.1,\"%s\")\nbg[ACTIVE]=shade(0.9,\"%s\")\nbg[SELECTED]=shade(0.97,\"%s\")\nfg[NORMAL]=\"%s\"\nfg[PRELIGHT]=\"%s\"\nfg[SELECTED]=\"%s\"\nfg[ACTIVE]=\"%s\"\n}\nwidget \"*PanelWidget*\" style \"gtk-theme-config-panel\"\nwidget \"*PanelApplet*\" style \"gtk-theme-config-panel\"\nwidget \"*fast-user-switch*\" style \"gtk-theme-config-panel\"\nwidget \"*CPUFreq*Applet*\" style \"gtk-theme-config-panel\"\nwidget \"*indicator-applet*\" style \"gtk-theme-config-panel\"\nclass \"PanelApp*\" style \"gtk-theme-config-panel\"\nclass \"PanelToplevel*\" style \"gtk-theme-config-panel\"\nwidget_class \"*PanelToplevel*\" style \"gtk-theme-config-panel\"\nwidget_class \"*notif*\" style \"gtk-theme-config-panel\"\nwidget_class \"*Notif*\" style \"gtk-theme-config-panel\"\nwidget_class \"*Tray*\" style \"gtk-theme-config-panel\" \nwidget_class \"*tray*\" style \"gtk-theme-config-panel\"\nwidget_class \"*computertemp*\" style \"gtk-theme-config-panel\"\nwidget_class \"*Applet*Tomboy*\" style \"gtk-theme-config-panel\"\nwidget_class \"*Applet*Netstatus*\" style \"gtk-theme-config-panel\"\nwidget \"*gdm-user-switch-menubar*\" style \"gtk-theme-config-panel\"\nwidget \"*Xfce*Panel*\" style \"gtk-theme-config-panel\"\nclass \"*Xfce*Panel*\" style \"gtk-theme-config-panel\"\n".printf(panelbg_value, panelbg_value, panelbg_value, panelbg_value, panelfg_value, panelfg_value, panelfg_value, panelfg_value);
		} else {
			panel_state1 = "/* panel-off";
			panel_state2 = "panel-off */";
			panel_gtk2 = "";
		}
		if (menu_switch.get_active()) {
			menu_state1 = "/* menu-on */";
			menu_state2 = "/* menu-on */";
			menu_gtk2 = "style\"gtk-theme-config-menu\"{\nbase[NORMAL]=\"%s\"\nbg[NORMAL]=\"%s\"\nbg[ACTIVE]=\"%s\"\nbg[INSENSITIVE]=\"%s\"\ntext[NORMAL]=\"%s\"\nfg[NORMAL]=\"%s\"\n}\nwidget_class\"*<GtkMenu>*\"style\"gtk-theme-config-menu\"\n".printf(menubg_value, menubg_value, menubg_value, menubg_value, menufg_value, menufg_value);
		} else {
			menu_state1 = "/* menu-off";
			menu_state2 = "menu-off */";;
			menu_gtk2 = "";
		}

		// Write config
		try {
			var dos = new DataOutputStream (gtk3_config_file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string ("/* GTK theme preferences */\n");
			string text = "%s\n@define-color selected_bg_color %s;\n@define-color selected_fg_color %s;\n@define-color theme_selected_bg_color @selected_bg_color;\n@define-color theme_selected_fg_color @selected_fg_color;\n%s\n%s\n@define-color panel_bg_color %s;\n@define-color panel_fg_color %s;\nPanelWidget,PanelApplet,PanelToplevel,PanelSeparator,.gnome-panel-menu-bar,PanelApplet > GtkMenuBar.menubar,PanelApplet > GtkMenuBar.menubar.menuitem,PanelMenuBar.menubar,PanelMenuBar.menubar.menuitem,PanelAppletFrame,UnityPanelWidget,.unity-panel{background-image:-gtk-gradient(linear,left top,left bottom,from(shade(@panel_bg_color,1.2)),to(shade(@panel_bg_color,0.8)));color:@panel_fg_color;}\n.unity-panel.menuitem,.unity-panel .menuitem{color:@panel_fg_color;}\n.unity-panel.menubar.menuitem:hover,.unity-panel.menubar .menuitem *:hover{border-color:shade(@panel_bg_color, 0.7);border-image:none;background-image:-gtk-gradient(linear,left top,left bottom,from(shade(@panel_bg_color, 0.97)),to(shade(@panel_bg_color, 0.82)));color:@panel_fg_color;}\nPanelApplet .button{border-color:transparent;border-image:none;background-image:-gtk-gradient(linear,left top,left bottom,from(shade(@panel_bg_color,1.2)),to(shade(@panel_bg_color,0.8)));color:@panel_fg_color;box-shadow:none;text-shadow:none;-unico-inner-stroke-width:0;}\nPanelApplet .button:active{border-color:shade(@panel_bg_color,0.8);border-image:none;background-image:-gtk-gradient(linear,left top,left bottom,from(shade(shade(@panel_bg_color,1.02),0.9)),to(shade(shade(@panel_bg_color,1.02),0.95)));color:@panel_fg_color;box-shadow:none;text-shadow:none;-unico-inner-stroke-width:0;}\nPanelApplet .button:prelight{border-color:transparent;border-image:none;background-image:-gtk-gradient(linear,left top,left bottom,from(shade(@panel_bg_color,1.2)),to(shade(@panel_bg_color,1.0)));color:@panel_fg_color;box-shadow:none;text-shadow:none;-unico-inner-stroke-width:0;}\nPanelApplet .button:active:prelight{border-color:shade(@panel_bg_color,0.8);border-image:none;background-image:-gtk-gradient(linear,left top,left bottom,from(shade(shade(@panel_bg_color,1.02),1.0)),to(shade(shade(@panel_bg_color,1.02),1.05)));color:@panel_fg_color;box-shadow:none;text-shadow:none;-unico-inner-stroke-width:0;}\nWnckPager,WnckTasklist{background-color:@panel_bg_color;}\n%s\n%s\n@define-color menu_bg_color %s;\n@define-color menu_fg_color %s;\nGtkTreeMenu.menu,GtkMenuToolButton.menu,GtkComboBox .menu{background-color:@menu_bg_color;}\n.primary-toolbar .button .menu,.toolbar .menu,.toolbar .primary-toolbar .menu,.menu{background-color:@menu_bg_color;color:@menu_fg_color;box-shadow:none;text-shadow:none;-unico-inner-stroke-width:0;}\n.menu.button:hover,.menu.button:active,.menu.button:active:insensitive,.menu.button:insensitive,.menu.button{background-color:@menu_bg_color;background-image:none;}\nGtkTreeMenu .menuitem *{color:@menu_fg_color;}\n.menuitem,.menu .menuitem{background-color:transparent;}\n.menu .menuitem:active,.menu .menuitem:hover{background-color:@theme_selected_bg_color;}\n.menu .menuitem:insensitive,.menu .menuitem *:insensitive{color:mix(@menu_fg_color,@menu_bg_color,0.5);}\n.menuitem.arrow{color:alpha(@menu_fg_color, 0.6);}\n.menuitem .entry{border-color:shade(@menu_bg_color,0.7);border-image:none;background-color:@menu_bg_color;background-image:none;color:@menu_fg_color;}\n.menuitem .accelerator{color:alpha(@menu_fg_color,0.6);}\n.menuitem .accelerator:insensitive{color:alpha(mix(@menu_fg_color,@menu_bg_color,0.5),0.6);text-shadow:none;}\n.menuitem.separator{color:shade(@menu_bg_color, 0.9);}\n.menuitem GtkCalendar,.menuitem GtkCalendar.button,.menuitem GtkCalendar.header,.menuitem GtkCalendar.view{border-color:shade(@menu_bg_color,0.8);border-image:none;background-color:@menu_bg_color;background-image:none;color:@menu_fg_color;}\n.menuitem GtkCalendar:inconsistent{color:mix(@menu_fg_color,@menu_bg_color,0.5);}\n%s".printf(select_state1, selectbg_value, selectfg_value, select_state2, panel_state1, panelbg_value, panelfg_value, panel_state2, menu_state1, menubg_value, menufg_value, menu_state2);
			uint8[] data = text.data;
			long written = 0;
			while (written < data.length) {
				written += dos.write (data[written:data.length]);
			}
		} catch (Error e) {
			stderr.printf ("Could not write gtk3 configuration: %s\n", e.message);
		}
		try {
			var dos = new DataOutputStream (gtk2_config_file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string ("# GTK theme preferences\n");
			string text = "%s\n%s".printf(panel_gtk2, menu_gtk2);
			uint8[] data = text.data;
			long written = 0;
			while (written < data.length) {
				written += dos.write (data[written:data.length]);
			}
		} catch (Error e) {
			stderr.printf ("Could not write gtk2 configuration: %s\n", e.message);
		}
	}

	void notify_change() {
		try {
			Process.spawn_command_line_async("notify-send -h int:transient:1 -i \"gtk-theme-config\" \"Changes applied.\" \"You might need to restart running applications.\"");
		} catch (Error e) {
			stderr.printf ("%s", e.message);
		}
	}
}

class ThemeConfigApp : Gtk.Application {
	internal ThemeConfigApp () {
		Object (application_id: "org.themeconfig.app");
	}

	protected override void activate () {
		var window = new ThemeConfigWindow (this);
		window.show_all ();
	}
}

int main (string[] args) {
	return new ThemeConfigApp ().run (args);
}

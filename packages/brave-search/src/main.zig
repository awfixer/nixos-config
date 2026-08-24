//! brave-search — chromeless GTK4 + WebKitGTK window pinned to search.brave.com.
//!
//! Usage:
//!   brave-search              open https://search.brave.com
//!   brave-search nix flakes   open results for "nix flakes"
//!   brave-search https://…    open that URL in-app when on brave, else system browser
//!
//! Single instance: a second launch reuses the first window and loads the new
//! query there. Links outside search.brave.com open via xdg-open.

const std = @import("std");

// webkit/webkit.h pulls in gtk4, gdk, glib and gobject declarations too.
const c = @cImport({
    @cInclude("webkit/webkit.h");
});

const app_id = "com.awfixer.BraveSearch";
const home_uri = "https://search.brave.com";
const search_base = "https://search.brave.com/search?q=";
// Plausible current Firefox/Linux UA — WebKitGTK's default advertises itself
// as an embedded tool and gets bot-walled quickly.
const user_agent = "Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0";
const accept_language = "en-US,en;q=0.9";

const KEY_Q: c.guint = 'q';
const KEY_F11: c.guint = 0xffc8; // GDK_KEY_F11

var g_app: ?*c.GtkApplication = null;
var g_win: ?*c.GtkWindow = null;
var g_view: ?*c.GtkWidget = null;
var g_fullscreen: bool = false;

pub fn main() !void {
    g_app = c.gtk_application_new(app_id, c.G_APPLICATION_HANDLES_COMMAND_LINE);
    if (g_app == null) return error.GtkApplicationNewFailed;
    defer c.g_object_unref(g_app);

    connectSignal(g_app, "command-line", &onCommandLine);
    connectSignal(g_app, "activate", &onActivate);

    const status = c.g_application_run(@ptrCast(g_app), 0, null);
    if (status != 0) return error.ApplicationRunFailed;
}

fn connectSignal(instance: anytype, detailed_signal: [*:0]const u8, handler: anytype) void {
    _ = c.g_signal_connect_data(@ptrCast(instance), detailed_signal, @ptrCast(handler), null, null, 0);
}

fn onActivate(application: ?*c.GApplication, user_data: ?*anyopaque) callconv(.c) void {
    _ = application;
    _ = user_data;
    ensureWindow();
}

fn onCommandLine(
    application: ?*c.GApplication,
    command_line: ?*c.GApplicationCommandLine,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = application;
    _ = user_data;

    var argc: c_int = 0;
    const argv = c.g_application_command_line_get_arguments(command_line, &argc);

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var query: ?[]const u8 = null;
    if (argc > 1) blk: {
        var total: usize = 0;
        for (1..@intCast(argc)) |i| total += argSlice(argv[i]).len + 1;
        const buf = arena.alloc(u8, total) catch break :blk;
        var n: usize = 0;
        for (1..@intCast(argc)) |i| {
            const part = argSlice(argv[i]);
            if (n > 0) {
                buf[n] = ' ';
                n += 1;
            }
            @memcpy(buf[n .. n + part.len], part);
            n += part.len;
        }
        const trimmed = std.mem.trim(u8, buf[0..n], " \t");
        if (trimmed.len > 0) query = trimmed;
    }
    c.g_strfreev(argv);

    ensureWindow();
    if (query) |q| navigate(arena, q) catch |err| std.debug.print("navigate failed: {s}\n", .{@errorName(err)});
    return 0;
}

fn argSlice(p: [*c]const u8) []const u8 {
    if (p == null) return "";
    return std.mem.sliceTo(p, 0);
}

fn ensureWindow() void {
    if (g_win != null) {
        presentWindow();
        return;
    }

    const win_raw = c.gtk_application_window_new(g_app);
    const win: ?*c.GtkWindow = @ptrCast(win_raw);
    g_win = win;

    c.gtk_window_set_title(win, "Search");
    c.gtk_window_set_default_size(win, 1000, 700);
    // No headerbar / CSD chrome.
    c.gtk_window_set_decorated(win, 0);

    const view_raw = c.webkit_web_view_new();
    g_view = view_raw;
    c.gtk_window_set_child(win, view_raw);

    const settings = c.webkit_web_view_get_settings(@ptrCast(view_raw));
    c.webkit_settings_set_user_agent(settings, user_agent);

    const session = c.webkit_network_session_get_default();
    if (session != null) {
        const data_manager = c.webkit_network_session_get_website_data_manager(session);
        if (data_manager != null)
            c.webkit_website_data_manager_set_accept_language(data_manager, accept_language);
    }

    connectSignal(view_raw, "decide-policy", &onDecidePolicy);

    addShortcut(win_raw, KEY_Q, c.GDK_CONTROL_MASK, &quitAction);
    addShortcut(win_raw, KEY_F11, 0, &fullscreenAction);

    _ = c.webkit_web_view_load_uri(@ptrCast(view_raw), home_uri);
    c.gtk_widget_grab_focus(view_raw);
    presentWindow();
}

fn presentWindow() void {
    if (g_win) |win| c.gtk_window_present(win);
}

fn navigate(arena: std.mem.Allocator, query: []const u8) !void {
    const target = try resolveTarget(arena, query);
    const uri = try arena.dupeZ(u8, target);
    if (g_view) |view| {
        _ = c.webkit_web_view_load_uri(@ptrCast(view), uri.ptr);
        c.gtk_widget_grab_focus(view);
    }
    presentWindow();
}

fn resolveTarget(arena: std.mem.Allocator, query: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, query, "https://") or std.mem.startsWith(u8, query, "http://"))
        return query;
    return buildSearchUrl(arena, query);
}

fn buildSearchUrl(arena: std.mem.Allocator, query: []const u8) ![]u8 {
    var extra: usize = 0;
    for (query) |ch| {
        if (!isUnreserved(ch)) extra += 2;
    }
    const url = try arena.alloc(u8, search_base.len + query.len + extra);
    @memcpy(url[0..search_base.len], search_base);
    var n = search_base.len;
    const hex = "0123456789ABCDEF";
    for (query) |ch| {
        if (isUnreserved(ch)) {
            url[n] = ch;
            n += 1;
        } else {
            url[n] = '%';
            url[n + 1] = hex[ch >> 4];
            url[n + 2] = hex[ch & 0x0f];
            n += 3;
        }
    }
    return url[0..n];
}

fn isUnreserved(ch: u8) bool {
    return std.ascii.isAlphanumeric(ch) or ch == '-' or ch == '_' or ch == '.' or ch == '~';
}

fn isInternalUri(uri: []const u8) bool {
    const prefixes = [_][]const u8{
        "https://search.brave.com",
        "http://search.brave.com",
        "about:",
        "data:",
        "blob:",
    };
    for (prefixes) |prefix| {
        if (std.mem.startsWith(u8, uri, prefix)) return true;
    }
    return false;
}

fn onDecidePolicy(
    web_view: ?*c.WebKitWebView,
    decision: ?*c.WebKitPolicyDecision,
    decision_type: c.WebKitPolicyDecisionType,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = web_view;
    _ = user_data;

    switch (decision_type) {
        .WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION => {
            const nav: ?*c.WebKitNavigationPolicyDecision = @ptrCast(decision);
            const action = c.webkit_navigation_policy_decision_get_navigation_action(nav);
            const request = c.webkit_navigation_action_get_request(action);
            const uri = std.mem.sliceTo(c.webkit_uri_request_get_uri(request), 0);

            // Middle-click or Ctrl-click always goes to the system browser,
            // plain clicks stay in-app only while on the search site.
            const button = c.webkit_navigation_action_get_mouse_button(action);
            const modifiers = c.webkit_navigation_action_get_modifiers(action);
            const ctrl_held = (modifiers & @intFromEnum(c.GDK_CONTROL_MASK)) != 0;

            if (button == 2 or ctrl_held or !isInternalUri(uri)) {
                openExternally(uri);
                c.webkit_policy_decision_ignore(decision);
                return 1;
            }
            return 0;
        },
        .WEBKIT_POLICY_DECISION_TYPE_NEW_WINDOW_ACTION => {
            const nav: ?*c.WebKitNavigationPolicyDecision = @ptrCast(decision);
            const action = c.webkit_navigation_policy_decision_get_navigation_action(nav);
            const request = c.webkit_navigation_action_get_request(action);
            const uri = std.mem.sliceTo(c.webkit_uri_request_get_uri(request), 0);
            openExternally(uri);
            c.webkit_policy_decision_ignore(decision);
            return 1;
        },
        else => return 0,
    }
}

fn openExternally(uri: []const u8) void {
    var zbuf: [4096]u8 = undefined;
    if (uri.len >= zbuf.len) return;
    @memcpy(zbuf[0..uri.len], uri);
    const zeroed = zbuf[0..uri.len :0];

    var child = std.process.Child.init(&.{ "xdg-open", zeroed }, std.heap.page_allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    child.spawn() catch |err| {
        std.debug.print("xdg-open failed: {s}\n", .{@errorName(err)});
        return;
    };
    _ = child.wait() catch {};
}

fn addShortcut(
    widget: ?*c.GtkWidget,
    keyval: c.guint,
    modifiers: c.GdkModifierType,
    func: *const fn (?*c.GtkWidget, ?*c.GVariant, ?*anyopaque) callconv(.c) c_int,
) void {
    const controller = c.gtk_shortcut_controller_new();
    const trigger = c.gtk_keyval_trigger_new(keyval, modifiers);
    const action = c.gtk_callback_action_new(func, null, null);
    const shortcut = c.gtk_shortcut_new(trigger, action);
    c.gtk_shortcut_controller_add_shortcut(controller, shortcut);
    c.gtk_widget_add_controller(widget, controller);
}

fn quitAction(_: ?*c.GtkWidget, _: ?*c.GVariant, _: ?*anyopaque) callconv(.c) c_int {
    if (g_win) |win| c.gtk_window_destroy(win);
    return 1;
}

fn fullscreenAction(_: ?*c.GtkWidget, _: ?*c.GVariant, _: ?*anyopaque) callconv(.c) c_int {
    if (g_win) |win| {
        if (g_fullscreen) {
            c.gtk_window_unfullscreen(win);
        } else {
            c.gtk_window_fullscreen(win);
        }
        g_fullscreen = !g_fullscreen;
    }
    return 1;
}

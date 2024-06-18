const std = @import("std");
const zap = @import("zap");
const mem = std.mem;
const print = std.debug.print;
const http = std.net.http;

fn handleRequest(r: zap.Request) void {
    if (!validateRequest(r)) {
        r.sendBody("Unauthorized") catch return;
        r.setStatus(zap.StatusCode.unauthorized);
        return;
    }

    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
        if (mem.eql(u8, the_path, "/info")) {
            info(r);
            return;
        }
        if (mem.eql(u8, the_path, "/loadTracks")) {
            loadTracks(r);
            return;
        }
    }

    r.setHeader("Content-Type", "text/html") catch return;
    r.sendBody("<html><body><h1>THIS IS FALLBACK!!!</h1></body></html>") catch return;
}

fn info(r: zap.Request) void {
    r.setHeader("Content-Type", "text/html") catch return;
    r.sendBody("<html><body><h1>ZigStream v0.0.1</h1></body></html>") catch return;
}

fn loadTracks(r: zap.Request) void {
    if (!mem.eql(u8, r.method orelse "-", "GET")) {
        r.setStatus(zap.StatusCode.bad_request);
        r.setHeader("Content-Type", "text/plain") catch return;
        r.sendBody("Method not allowed") catch return;
        return;
    }
    if (r.getParamSlice("identifier")) |id| {
        std.debug.print("Identifier: {s}\n", .{id});
        r.setHeader("Content-Type", "application/json") catch return;
        r.sendBody(id) catch return;
    }
    r.setHeader("Content-Type", "application/json") catch return;
    r.setStatus(zap.StatusCode.ok);
    r.sendBody("{\"loadtype\": \"empty\", \"tracks\": {}}") catch return;
}

fn validateRequest(r: zap.Request) bool {
    const pass = "youshallnotpass";
    const head = r.getHeader("auth");
    if (head) |auth| {
        if (std.mem.eql(u8, auth, pass)) {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = handleRequest,
        .log = false,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}

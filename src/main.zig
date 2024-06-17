const std = @import("std");
const zap = @import("zap");
const mem = std.mem;

fn handleRequest(r: zap.Request) void {
    if (!validateRequest(r)) {
        r.sendBody("Unauthorized, haha u suck") catch return;
        r.setStatus(zap.StatusCode.unauthorized);
        return;
    }

    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
        if (mem.eql(u8, the_path, "/info")) {
            info(r);
            return;
        }
        if (mem.eql(u8, the_path, "/")) {
            r.setHeader("Content-Type", "text/html") catch return;
            r.sendBody("<html><body><h1>HELLO WORLD!!!</h1></body></html>") catch return;
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

fn validateRequest(r: zap.Request) bool {
    const pass = "youshallnotpass";
    const head = r.getHeader("Authorization");
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

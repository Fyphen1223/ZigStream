const std = @import("std");
const zap = @import("zap");
const print = @import("std").debug.print;

const ZigStream = struct {
    port: u8,
    config: []const u16,
    listener: zap.HttpListener,
    pub fn init(port: u8) ZigStream {
        return ZigStream{ .port = port };
    }

    pub fn boot(self: *ZigStream) bool {
        self.listener = zap.HttpListener.init(.{ .port = self.port, .on_request = handleRequest, .log = true, .max_clients = 100000 });
        try self.listener.listen();
        print("Listening on 0.0.0.0:3000\n", .{});
        zap.start(.{
            .threads = 2,
            .workers = 2,
        });
        return true;
    }
    fn handleRequest(r: zap.Request) void {
        if (r.path) |the_path| {
            std.debug.print("PATH: {s}\n", .{the_path});
        }

        if (r.query) |the_query| {
            std.debug.print("QUERY: {s}\n", .{the_query});
        }
        r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
    }
};

pub fn main() !void {
    const instance: ZigStream = ZigStream.init(8080);
    instance.boot();
}

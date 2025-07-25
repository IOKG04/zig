const std = @import("../../std.zig");
const maxInt = std.math.maxInt;
const linux = std.os.linux;
const SYS = linux.SYS;
const iovec = std.posix.iovec;
const iovec_const = std.posix.iovec_const;
const socklen_t = linux.socklen_t;
const stack_t = linux.stack_t;
const sigset_t = linux.sigset_t;
const uid_t = linux.uid_t;
const gid_t = linux.gid_t;
const pid_t = linux.pid_t;
const sockaddr = linux.sockaddr;
const timespec = linux.timespec;

pub fn syscall0(number: SYS) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
        : .{ .memory = true });
}

pub fn syscall1(number: SYS, arg1: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
        : .{ .memory = true });
}

pub fn syscall2(number: SYS, arg1: usize, arg2: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
        : .{ .memory = true });
}

pub fn syscall3(number: SYS, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
          [arg3] "{r2}" (arg3),
        : .{ .memory = true });
}

pub fn syscall4(number: SYS, arg1: usize, arg2: usize, arg3: usize, arg4: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
          [arg3] "{r2}" (arg3),
          [arg4] "{r3}" (arg4),
        : .{ .memory = true });
}

pub fn syscall5(number: SYS, arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
          [arg3] "{r2}" (arg3),
          [arg4] "{r3}" (arg4),
          [arg5] "{r4}" (arg5),
        : .{ .memory = true });
}

pub fn syscall6(
    number: SYS,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
    arg5: usize,
    arg6: usize,
) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (@intFromEnum(number)),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
          [arg3] "{r2}" (arg3),
          [arg4] "{r3}" (arg4),
          [arg5] "{r4}" (arg5),
          [arg6] "{r5}" (arg6),
        : .{ .memory = true });
}

pub fn clone() callconv(.naked) usize {
    // __clone(func, stack, flags, arg, ptid, tls, ctid)
    //         r0,   r1,    r2,    r3,  +0,   +4,  +8
    //
    // syscall(SYS_clone, flags, stack, ptid, tls, ctid)
    //         r7         r0,    r1,    r2,   r3,  r4
    asm volatile (
        \\    stmfd sp!,{r4,r5,r6,r7}
        \\    mov r7,#120 // SYS_clone
        \\    mov r6,r3
        \\    mov r5,r0
        \\    mov r0,r2
        \\    and r1,r1,#-16
        \\    ldr r2,[sp,#16]
        \\    ldr r3,[sp,#20]
        \\    ldr r4,[sp,#24]
        \\    svc 0
        \\    tst r0,r0
        \\    beq 1f
        \\    ldmfd sp!,{r4,r5,r6,r7}
        \\    bx lr
        \\
        \\    // https://github.com/llvm/llvm-project/issues/115891
        \\1:  mov r7, #0
        \\    mov r11, #0
        \\    mov lr, #0
        \\
        \\    mov r0,r6
        \\    bl 3f
        \\    mov r7,#1 // SYS_exit
        \\    svc 0
        \\
        \\3:  bx r5
    );
}

pub fn restore() callconv(.naked) noreturn {
    switch (@import("builtin").zig_backend) {
        .stage2_c => asm volatile (
            \\ mov r7, %[number]
            \\ svc #0
            :
            : [number] "I" (@intFromEnum(SYS.sigreturn)),
            : .{ .memory = true }),
        else => asm volatile (
            \\ svc #0
            :
            : [number] "{r7}" (@intFromEnum(SYS.sigreturn)),
            : .{ .memory = true }),
    }
}

pub fn restore_rt() callconv(.naked) noreturn {
    switch (@import("builtin").zig_backend) {
        .stage2_c => asm volatile (
            \\ mov r7, %[number]
            \\ svc #0
            :
            : [number] "I" (@intFromEnum(SYS.rt_sigreturn)),
            : .{ .memory = true }),
        else => asm volatile (
            \\ svc #0
            :
            : [number] "{r7}" (@intFromEnum(SYS.rt_sigreturn)),
            : .{ .memory = true }),
    }
}

pub const F = struct {
    pub const DUPFD = 0;
    pub const GETFD = 1;
    pub const SETFD = 2;
    pub const GETFL = 3;
    pub const SETFL = 4;

    pub const SETOWN = 8;
    pub const GETOWN = 9;
    pub const SETSIG = 10;
    pub const GETSIG = 11;

    pub const GETLK = 12;
    pub const SETLK = 13;
    pub const SETLKW = 14;

    pub const RDLCK = 0;
    pub const WRLCK = 1;
    pub const UNLCK = 2;

    pub const SETOWN_EX = 15;
    pub const GETOWN_EX = 16;

    pub const GETOWNER_UIDS = 17;
};

pub const VDSO = struct {
    pub const CGT_SYM = "__vdso_clock_gettime";
    pub const CGT_VER = "LINUX_2.6";
};

pub const HWCAP = struct {
    pub const SWP = 1 << 0;
    pub const HALF = 1 << 1;
    pub const THUMB = 1 << 2;
    pub const @"26BIT" = 1 << 3;
    pub const FAST_MULT = 1 << 4;
    pub const FPA = 1 << 5;
    pub const VFP = 1 << 6;
    pub const EDSP = 1 << 7;
    pub const JAVA = 1 << 8;
    pub const IWMMXT = 1 << 9;
    pub const CRUNCH = 1 << 10;
    pub const THUMBEE = 1 << 11;
    pub const NEON = 1 << 12;
    pub const VFPv3 = 1 << 13;
    pub const VFPv3D16 = 1 << 14;
    pub const TLS = 1 << 15;
    pub const VFPv4 = 1 << 16;
    pub const IDIVA = 1 << 17;
    pub const IDIVT = 1 << 18;
    pub const VFPD32 = 1 << 19;
    pub const IDIV = IDIVA | IDIVT;
    pub const LPAE = 1 << 20;
    pub const EVTSTRM = 1 << 21;
};

pub const Flock = extern struct {
    type: i16,
    whence: i16,
    __pad0: [4]u8,
    start: off_t,
    len: off_t,
    pid: pid_t,
    __unused: [4]u8,
};

pub const blksize_t = i32;
pub const nlink_t = u32;
pub const time_t = isize;
pub const mode_t = u32;
pub const off_t = i64;
pub const ino_t = u64;
pub const dev_t = u64;
pub const blkcnt_t = i64;

// The `stat` definition used by the Linux kernel.
pub const Stat = extern struct {
    dev: dev_t,
    __dev_padding: u32,
    __ino_truncated: u32,
    mode: mode_t,
    nlink: nlink_t,
    uid: uid_t,
    gid: gid_t,
    rdev: dev_t,
    __rdev_padding: u32,
    size: off_t,
    blksize: blksize_t,
    blocks: blkcnt_t,
    atim: timespec,
    mtim: timespec,
    ctim: timespec,
    ino: ino_t,

    pub fn atime(self: @This()) timespec {
        return self.atim;
    }

    pub fn mtime(self: @This()) timespec {
        return self.mtim;
    }

    pub fn ctime(self: @This()) timespec {
        return self.ctim;
    }
};

pub const timeval = extern struct {
    sec: i32,
    usec: i32,
};

pub const timezone = extern struct {
    minuteswest: i32,
    dsttime: i32,
};

pub const mcontext_t = extern struct {
    trap_no: usize,
    error_code: usize,
    oldmask: usize,
    arm_r0: usize,
    arm_r1: usize,
    arm_r2: usize,
    arm_r3: usize,
    arm_r4: usize,
    arm_r5: usize,
    arm_r6: usize,
    arm_r7: usize,
    arm_r8: usize,
    arm_r9: usize,
    arm_r10: usize,
    arm_fp: usize,
    arm_ip: usize,
    arm_sp: usize,
    arm_lr: usize,
    arm_pc: usize,
    arm_cpsr: usize,
    fault_address: usize,
};

pub const ucontext_t = extern struct {
    flags: usize,
    link: ?*ucontext_t,
    stack: stack_t,
    mcontext: mcontext_t,
    sigmask: [1024 / @bitSizeOf(c_ulong)]c_ulong, // Currently a libc-compatible (1024-bit) sigmask
    regspace: [64]u64,
};

/// TODO
pub const getcontext = {};

pub const Elf_Symndx = u32;

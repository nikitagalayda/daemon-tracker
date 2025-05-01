pub const FileOpenError = error{
    FileNotFound,
    DirNotFound,
};

pub const MatchError = error{
    MatchNotFound,
};

pub const ArgumentError = error{
    InvalidArgument,
};

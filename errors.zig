pub const FileOpenError = error{
    FileNotFound,
    DirNotFound,
};

pub const MatchError = error{
    MatchNotFound,
};

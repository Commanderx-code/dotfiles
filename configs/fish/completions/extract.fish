# Offer only directories and the archive types extract can unpack.
function __extract_archives
    # Each candidate may carry a tab and a description after the path.
    __fish_complete_path (commandline --current-token) \
        | string match --regex '^[^\t]*(?:/|\.tar|\.tar\.gz|\.tgz|\.tar\.bz2|\.tbz2|\.tar\.xz|\.txz|\.tar\.zst|\.zip|\.gz|\.bz2|\.xz|\.7z|\.rar)(?:\t.*)?$'
end

complete -c extract -f -n __fish_is_first_arg -a '(__extract_archives)'

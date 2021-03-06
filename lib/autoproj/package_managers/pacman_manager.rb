module Autoproj
    module PackageManagers
        # Package manager interface for systems that use pacman (i.e. arch) as
        # their package manager
        class PacmanManager < ShellScriptManager
            def initialize(ws)
                super(ws, true,
                        "pacman -Sy --needed '%s'",
                        "pacman -Sy --needed --noconfirm '%s'")
            end
        end
    end
end


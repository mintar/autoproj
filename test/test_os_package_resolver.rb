require 'autoproj/test'

module Autoproj
    describe OSPackageResolver do
        include Autoproj
        FOUND_PACKAGES = OSPackageResolver::FOUND_PACKAGES
        FOUND_NONEXISTENT = OSPackageResolver::FOUND_NONEXISTENT

        def setup
            OSPackageResolver.operating_system = [['test', 'debian', 'default'], ['v1.0', 'v1', 'default']]
            super
        end

        def test_it_initialies_itself_with_the_global_operating_system
            OSPackageResolver.operating_system = [['test', 'debian', 'default'], ['v1.0', 'v1', 'default']]
            resolver = OSPackageResolver.new
            assert_equal resolver.operating_system, OSPackageResolver.operating_system
        end

        def test_supported_operating_system
            resolver = OSPackageResolver.new
            resolver.operating_system = [['test', 'debian', 'default'], ['v1.0', 'v1', 'default']]
            assert(resolver.supported_operating_system?)
            resolver.operating_system = [['test', 'default'], ['v1.0', 'v1', 'default']]
            assert(!resolver.supported_operating_system?)
        end

        def create_osdep(data, file = nil)
            if data
                osdeps = OSPackageResolver.new(Hash['pkg' => data], file)
            else
                osdeps = OSPackageResolver.new(Hash.new, file)
            end

            # Mock the package handlers
            osdeps.os_package_manager = 'apt-dpkg'
            osdeps.package_managers.clear
            osdeps.package_managers << 'apt-dpkg' << 'gem' << 'pip'
            flexmock(osdeps)
        end

        def test_resolve_package_calls_specific_formatting
            data = { 'test' => {
                        'v1.0' => 'pkg1.0 blabla',
                        'v1.1' => 'pkg1.1 bloblo',
                        'default' => 'pkgdef'
                     }
            }
            osdeps = create_osdep(data)
            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0 blabla']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_package_applies_aliases
            data = { 'test' => {
                        'v1.0' => 'pkg1.0',
                        'v1.1' => 'pkg1.1',
                        'default' => 'pkgdef'
                     }
            }
            OSPackageResolver.alias('pkg', 'bla')
            osdeps = create_osdep(data)
            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0']]]
            assert_equal expected, osdeps.resolve_package('bla')
        end

        def test_resolve_specific_os_name_and_version_single_package
            data = { 'test' => {
                        'v1.0' => 'pkg1.0',
                        'v1.1' => 'pkg1.1',
                        'default' => 'pkgdef'
                     }
            }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_package_list
            data = { 'test' => {
                        'v1.0' => ['pkg1.0', 'other_pkg'],
                        'v1.1' => 'pkg1.1',
                        'default' => 'pkgdef'
                     }
            }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0', 'other_pkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_ignore
            data = { 'test' => {
                        'v1.0' => 'ignore',
                        'v1.1' => 'pkg1.1',
                        'default' => 'pkgdef'
                     }
            }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, []]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_fallback
            data = { 'test' => 
                     { 'v1.1' => 'pkg1.1',
                       'default' => 'pkgdef'
                     }
                   }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkgdef']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_nonexistent
            data = { 'test' => {
                        'v1.0' => 'nonexistent',
                        'v1.1' => 'pkg1.1',
                        'default' => 'pkgdef'
                     }
            }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_NONEXISTENT, []]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_not_found
            data = { 'test' => { 'v1.1' => 'pkg1.1', } }
            osdeps = create_osdep(data)
            assert_equal [], osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_single_package
            data = { 'test' => 'pkg1.0', 'other_test' => 'pkg1.1', 'default' => 'pkgdef' }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_package_list
            data = { 'test' => ['pkg1.0', 'other_pkg'], 'other_test' => 'pkg1.1', 'default' => 'pkgdef' }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1.0', 'other_pkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_ignore
            data = { 'test' => 'ignore', 'other_test' => 'pkg1.1', 'default' => 'pkgdef' }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, []]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_fallback
            data = { 'other_test' => 'pkg1.1', 'default' => 'pkgdef' }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkgdef']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_nonexistent
            data = { 'test' => 'nonexistent', 'other_test' => 'pkg1.1' }
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_NONEXISTENT, []]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_specific_os_name_and_version_not_found
            data = { 'other_test' => 'pkg1.1' }
            osdeps = create_osdep(data)

            assert_equal [], osdeps.resolve_package('pkg')
        end

        def test_resolve_os_name_global_and_specific_packages
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => 'pkg1.1',
                  'other_test' => 'pkg1.1',
                  'default' => 'nonexistent'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2', 'pkg1.1']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_name_global_and_specific_does_not_exist
            data = [
                'global_pkg1', 'global_pkg2',
                {
                  'other_test' => 'pkg1.1',
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_name_global_and_nonexistent
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => 'nonexistent',
                  'other_test' => 'pkg1.1'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_NONEXISTENT, ['global_pkg1', 'global_pkg2']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_name_global_and_ignore
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => 'ignore',
                  'other_test' => 'pkg1.1'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_version_global_and_specific_packages
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => ['pkg0', 'pkg1', { 'v1.0' => 'pkg1.0' }],
                  'other_test' => 'pkg1.1',
                  'default' => 'nonexistent'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2', 'pkg0', 'pkg1', 'pkg1.0']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_version_global_and_specific_nonexistent
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => ['pkg0', 'pkg1', { 'v1.0' => 'nonexistent' }],
                  'other_test' => 'pkg1.1',
                  'default' => 'nonexistent'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_NONEXISTENT, ['global_pkg1', 'global_pkg2', 'pkg0', 'pkg1']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_version_global_and_specific_ignore
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => ['pkg0', 'pkg1', { 'v1.0' => 'ignore' }],
                  'other_test' => 'pkg1.1',
                  'default' => 'nonexistent'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2', 'pkg0', 'pkg1']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_os_version_global_and_specific_does_not_exist
            data = [
                'global_pkg1', 'global_pkg2',
                { 'test' => ['pkg0', 'pkg1', { 'v1.1' => 'pkg1.1' }],
                  'other_test' => 'pkg1.1',
                  'default' => 'nonexistent'
                }
            ]
            osdeps = create_osdep(data)

            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['global_pkg1', 'global_pkg2', 'pkg0', 'pkg1']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_osindep_packages_global
            data = 'gem'
            osdeps = create_osdep(data)
            expected = [['gem', FOUND_PACKAGES, ['pkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')

            data = { 'gem' => 'gempkg' }
            osdeps = create_osdep(data)
            expected = [['gem', FOUND_PACKAGES, ['gempkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')

            data = { 'gem' => ['gempkg', 'gempkg1'] }
            osdeps = create_osdep(data)
            expected = [['gem', FOUND_PACKAGES, ['gempkg', 'gempkg1']]]
            assert_equal expected, osdeps.resolve_package('pkg')

            data = 'pip'
            osdeps = create_osdep(data)
            expected = [['pip', FOUND_PACKAGES, ['pkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_osindep_packages_specific
            data = ['gem', { 'test' => { 'gem' => 'gempkg' } } ]
            osdeps = create_osdep(data)
            expected = [['gem', FOUND_PACKAGES, ['pkg', 'gempkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_specific_os_version_supersedes_nonspecific_one
            data = { 'debian' => 'binary_package', 'test' => { 'gem' => 'gempkg' } }
            osdeps = create_osdep(data)
            expected = [['gem', FOUND_PACKAGES, ['gempkg']]]
            assert_equal expected, osdeps.resolve_package('pkg')

            data = { 'default' => { 'gem' => 'gem_package' }, 'test' => 'binary_package' }
            osdeps = create_osdep(data)
            expected = [[osdeps.os_package_manager, FOUND_PACKAGES, ['binary_package']]]
            assert_equal expected, osdeps.resolve_package('pkg')
        end

        def test_resolve_mixed_os_and_osindep_dependencies
            data = { 'test' => { 'default' => 'ospkg', 'gem' => 'gempkg' } }

            osdeps = create_osdep(data)
            expected = [
                [osdeps.os_package_manager, FOUND_PACKAGES, ['ospkg']],
                ['gem', FOUND_PACKAGES, ['gempkg']]
            ].to_set
            assert_equal expected, osdeps.resolve_package('pkg').to_set
        end

        def test_availability_of
            osdeps = flexmock(OSPackageResolver.new)
            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1']],
                 ['gem', FOUND_PACKAGES, ['gempkg1']]])
            assert_equal OSPackageResolver::AVAILABLE, osdeps.availability_of('pkg0')

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, []],
                 ['gem', FOUND_PACKAGES, ['gempkg1']]])
            assert_equal OSPackageResolver::AVAILABLE, osdeps.availability_of('pkg0')

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, []],
                 ['gem', FOUND_PACKAGES, []]])
            assert_equal OSPackageResolver::IGNORE, osdeps.availability_of('pkg0')

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1']],
                 ['gem', FOUND_NONEXISTENT, []]])
            assert_equal OSPackageResolver::NONEXISTENT, osdeps.availability_of('pkg0')

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return([])
            assert_equal OSPackageResolver::WRONG_OS, osdeps.availability_of('pkg0')

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(nil)
            assert_equal OSPackageResolver::NO_PACKAGE, osdeps.availability_of('pkg0')
        end

        def test_has_p
            osdeps = flexmock(OSPackageResolver.new)
            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::AVAILABLE)
            assert(osdeps.has?('pkg0'))

            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::IGNORE)
            assert(osdeps.has?('pkg0'))

            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::UNKNOWN_OS)
            assert(!osdeps.has?('pkg0'))

            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::WRONG_OS)
            assert(!osdeps.has?('pkg0'))

            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::NONEXISTENT)
            assert(!osdeps.has?('pkg0'))

            osdeps.should_receive(:availability_of).with('pkg0').once.
                and_return(OSPackageResolver::NO_PACKAGE)
            assert(!osdeps.has?('pkg0'))
        end

        def test_resolve_os_packages
            osdeps = flexmock(OSPackageResolver.new)
            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg0']]])
            osdeps.should_receive(:resolve_package).with('pkg1').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1']],
                 ['gem', FOUND_PACKAGES, ['gempkg1']]])
            osdeps.should_receive(:resolve_package).with('pkg2').once.and_return(
                [['gem', FOUND_PACKAGES, ['gempkg2']]])
            expected =
                [[osdeps.os_package_manager, ['pkg0', 'pkg1']],
                 ['gem', ['gempkg1', 'gempkg2']]]
            assert_equal expected, osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2'])

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg0']]])
            osdeps.should_receive(:resolve_package).with('pkg1').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, []]])
            osdeps.should_receive(:resolve_package).with('pkg2').once.and_return(
                [['gem', FOUND_PACKAGES, ['gempkg2']]])
            expected =
                [[osdeps.os_package_manager, ['pkg0']],
                 ['gem', ['gempkg2']]]
            assert_equal expected, osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2'])

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(nil)
            osdeps.should_receive(:resolve_package).with('pkg1').never
            osdeps.should_receive(:resolve_package).with('pkg2').never
            assert_raises(MissingOSDep) { osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2']) }

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg0']]])
            osdeps.should_receive(:resolve_package).with('pkg1').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1']],
                 ['gem', FOUND_PACKAGES, ['gempkg1']]])
            osdeps.should_receive(:resolve_package).with('pkg2').once.and_return(nil)
            expected =
                [[osdeps.os_package_manager, ['pkg0']],
                 ['gem', ['gempkg1', 'gempkg2']]]
            assert_raises(MissingOSDep) { osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2']) }

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_NONEXISTENT, ['pkg0']]])
            osdeps.should_receive(:resolve_package).with('pkg1').never
            osdeps.should_receive(:resolve_package).with('pkg2').never
            assert_raises(MissingOSDep) { osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2']) }

            osdeps.should_receive(:resolve_package).with('pkg0').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg0']]])
            osdeps.should_receive(:resolve_package).with('pkg1').once.and_return(
                [[osdeps.os_package_manager, FOUND_PACKAGES, ['pkg1']],
                 ['gem', FOUND_NONEXISTENT, ['gempkg1']]])
            osdeps.should_receive(:resolve_package).with('pkg2').never
            assert_raises(MissingOSDep) { osdeps.resolve_os_packages(['pkg0', 'pkg1', 'pkg2']) }
        end

        def test_resolve_os_packages_unsupported_os_non_existent_dependency
            osdeps = create_osdep(nil)
            flexmock(osdeps).should_receive(:supported_operating_system?).and_return(false)
            assert_raises(MissingOSDep) { osdeps.resolve_os_packages(['a_package']) }
        end

        def test_resolve_package_availability_unsupported_os_non_existent_dependency
            osdeps = create_osdep(nil)
            flexmock(osdeps).should_receive(:supported_operating_system?).and_return(false)
            assert_equal OSPackageResolver::NO_PACKAGE, osdeps.availability_of('a_package')
        end

        def test_resolve_package_availability_unsupported_os_existent_dependency
            osdeps = create_osdep({ 'an_os' => 'bla' })
            flexmock(osdeps).should_receive(:supported_operating_system?).and_return(false)
            assert_equal OSPackageResolver::WRONG_OS, osdeps.availability_of('pkg')
        end

        DATA_DIR = File.expand_path('data', File.dirname(__FILE__))
        def test_os_from_os_release_returns_nil_if_the_os_release_file_is_not_found
            assert !OSPackageResolver.os_from_os_release('does_not_exist')
        end
        def test_os_from_os_release_handles_quoted_and_unquoted_fields
            names, versions = OSPackageResolver.os_from_os_release(
                File.join(DATA_DIR, 'os_release.with_missing_optional_fields'))
            assert_equal ['name'], names
            assert_equal ['version_id'], versions
        end
        def test_os_from_os_release_handles_optional_fields
            names, versions = OSPackageResolver.os_from_os_release(
                File.join(DATA_DIR, 'os_release.with_missing_optional_fields'))
            assert_equal ['name'], names
            assert_equal ['version_id'], versions
        end
        def test_os_from_os_release_parses_the_version_field
            _, versions = OSPackageResolver.os_from_os_release(
                File.join(DATA_DIR, 'os_release.with_complex_version_field'))
            assert_equal ['version_id', 'version', 'codename', 'codename_bis'], versions
        end
        def test_os_from_os_release_removes_duplicate_values
            names, versions = OSPackageResolver.os_from_os_release(
                File.join(DATA_DIR, 'os_release.with_duplicate_values'))
            assert_equal ['id'], names
            assert_equal ['version_id', 'codename'], versions
        end
        def test_os_from_lsb_returns_nil_if_lsb_release_is_not_found_in_path
            flexmock(ENV).should_receive('[]').with('PATH').and_return('')
            assert !OSPackageResolver.os_from_lsb
        end

        def test_merge_issues_a_warning_if_two_definitions_differ_by_the_operating_system_packages
            OSPackageResolver.operating_system = [['os0'], []]
            osdeps0 = create_osdep(Hash['os0' => ['osdep0'], 'gem' => ['gem0']], 'bla/bla')
            osdeps1 = create_osdep(Hash['os0' => ['osdep1'], 'gem' => ['gem0']], 'bla/blo')
            flexmock(Autoproj).should_receive(:warn).once.
                with(->(msg) { msg =~ /bla\/bla/ && msg =~ /bla\/blo/ })
            osdeps0.merge(osdeps1)
        end
        def test_merge_issues_a_warning_if_two_definitions_differ_by_an_os_independent_package
            OSPackageResolver.operating_system = [['os0'], []]
            osdeps0 = create_osdep(Hash['os0' => ['osdep0'], 'gem' => ['gem0']], 'bla/bla')
            osdeps1 = create_osdep(Hash['os0' => ['osdep0'], 'gem' => ['gem1']], 'bla/blo')
            flexmock(Autoproj).should_receive(:warn).once.
                with(->(msg) { msg =~ /bla\/bla/ && msg =~ /bla\/blo/ })
            osdeps0.merge(osdeps1)
        end
        def test_merge_does_not_issue_a_warning_if_two_definitions_are_identical_for_the_local_operating_system
            OSPackageResolver.operating_system = [['os0'], []]
            osdeps0 = create_osdep(Hash['os0' => ['osdep0'], 'gem' => ['gem0'], 'os1' => ['osdep0']], 'bla/bla')
            osdeps1 = create_osdep(Hash['os0' => ['osdep0'], 'gem' => ['gem0'], 'os1' => ['osdep1']], 'bla/blo')
            flexmock(Autoproj).should_receive(:warn).never
            osdeps0.merge(osdeps1)
        end

        describe "prefer_indep_over_os_packages is set" do
            before do
                OSPackageResolver.operating_system = [['os0'], ['v0']]
            end
            
            def create_osdep(*)
                resolver = super
                resolver.prefer_indep_over_os_packages = true
                resolver
            end

            it "resolves the default entry first" do
                resolver = create_osdep(Hash['os0' => ['osdep0'], 'default' => 'gem'], 'bla/bla')
                assert_equal [['gem', ['pkg']]], resolver.resolve_os_packages(['pkg'])
            end
            it "resolves the default entry first" do
                resolver = create_osdep(Hash['os0' => ['osdep0'], 'default' => Hash['gem' => 'gem0']], 'bla/bla')
                assert_equal [['gem', ['gem0']]], resolver.resolve_os_packages(['pkg'])
            end
            it "falls back to the OS-specific entry if there is no default entry" do
                resolver = create_osdep(Hash['os0' => ['osdep0']], 'bla/bla')
                assert_equal [['apt-dpkg', ['osdep0']]], resolver.resolve_os_packages(['pkg'])
            end
            it "does not affect os versions, only os names" do
                resolver = create_osdep(Hash['os0' => Hash['v0' => 'osdep0', 'default' => 'gem']], 'bla/bla')
                assert_equal [['apt-dpkg', ['osdep0']]], resolver.resolve_os_packages(['pkg'])
            end
        end
    end
end


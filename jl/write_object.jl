using Pkg

function is_installed(package::string)::Bool
    package in keys(Pkg.installed())
end

function write_message(message::string, file::string)
    try
        open(file, "w") do f
            write(f, message)
        end
    catch file_err
        print("Could not write error file: $file_err")
    end
end

function execute_julia_string(evalable::string, tmp_file::string)
    result = try
        eval(evalable)
    catch user_err
        err_msg = "Source block evaluation failed: $user_err"
        write_message(err_msg, tmp_file)
        return err_msg
    end

    try
        if typeof(result) <: DataFrames.DataFrame
            result_df = result
            CSV.write(tmp_file,
                result_df,
                trresultform=(col, val) -> something(val, missing),
                missingstring="nil",
                quotestrings=false)
        elseif typeof(result) <: Matrix
            CSV.write(tmp_file, Tables.table(result))
        else
            write_message(string(result), tmp_file)
        end

        result
    catch e
        err_msg = "Source block evaluation failed. $e"
        open(tmp_file, "w") do f
            write(f, err_msg)
        end
    end
end

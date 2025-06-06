/*PGR-GNU*****************************************************************
File: boyerMyrvold_driver.cpp

Generated with Template by:
Copyright (c) 2020 pgRouting developers
Mail: project@pgrouting.org

Function's developer:
Copyright (c) 2020 Himanshu Raj
Mail: raj.himanshu2@gmail.com

------

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

********************************************************************PGR-GNU*/

#include "drivers/planar/boyerMyrvold_driver.h"

#include <vector>
#include <algorithm>
#include <string>

#include "cpp_common/pgr_alloc.hpp"
#include "cpp_common/pgr_assert.hpp"
#include "cpp_common/pgdata_getters.hpp"
#include "c_types/iid_t_rt.h"

#include "planar/pgr_boyerMyrvold.hpp"
#include "cpp_common/pgr_base_graph.hpp"



void
pgr_do_boyerMyrvold(
                const char *edges_sql,

                IID_t_rt **return_tuples,
                size_t *return_count,
                char ** log_msg,
                char ** notice_msg,
                char ** err_msg) {
    using pgrouting::pgr_alloc;
    using pgrouting::to_pg_msg;
    using pgrouting::pgr_free;
    using pgrouting::pgget::get_edges;

    std::ostringstream log;
    std::ostringstream err;
    std::ostringstream notice;
    const char *hint = nullptr;
    try {
        pgassert(!(*log_msg));
        pgassert(!(*notice_msg));
        pgassert(!(*err_msg));
        pgassert(!(*return_tuples));
        pgassert(*return_count == 0);

        std::vector<IID_t_rt> results;
        std::string logstr;

        graphType gType = UNDIRECTED;

        hint = edges_sql;
        auto edges = get_edges(std::string(edges_sql), true, true);

        if (edges.empty()) {
            throw std::string("No edges found");
        }
        hint = nullptr;

        log << "Working with Undirected Graph\n";
        pgrouting::UndirectedGraph undigraph(directed);
        undigraph.insert_edges(edges);
        pgrouting::functions::Pgr_boyerMyrvold<pgrouting::UndirectedGraph> fn_boyerMyrvold;
        results = fn_boyerMyrvold.boyerMyrvold(undigraph);
        logstr += fn_boyerMyrvold.get_log();
        log << logstr;


        auto count = results.size();

        if (count == 0) {
            (*return_tuples) = NULL;
            (*return_count) = 0;
            notice <<
                "No Vertices";
            *log_msg = to_pg_msg(notice);
            return;
        }

        (*return_tuples) = pgr_alloc(count, (*return_tuples));
        for (size_t i = 0; i < count; i++) {
            *((*return_tuples) + i) = results[i];
        }
        (*return_count) = count;

        pgassert(*err_msg == NULL);
        *log_msg = to_pg_msg(log);
        *notice_msg = to_pg_msg(notice);
    } catch (AssertFailedException &except) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << except.what();
        *err_msg = to_pg_msg(err);
        *log_msg = to_pg_msg(log);
    } catch (const std::string &ex) {
        *err_msg = to_pg_msg(ex);
        *log_msg = hint? to_pg_msg(hint) : to_pg_msg(log);
    } catch (std::exception &except) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << except.what();
        *err_msg = to_pg_msg(err);
        *log_msg = to_pg_msg(log);
    } catch(...) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << "Caught unknown exception!";
        *err_msg = to_pg_msg(err);
        *log_msg = to_pg_msg(log);
    }
}

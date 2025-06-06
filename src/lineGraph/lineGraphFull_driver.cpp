/*PGR-GNU*****************************************************************
File: lineGraphFull_driver.cpp

Generated with Template by:
Copyright (c) 2015 pgRouting developers
Mail: project@pgrouting.org

Function's developer:
Copyright (c) 2017 Anthony Nicola Tasca
Mail: atasca10 at gmail.com

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

#include "drivers/lineGraph/lineGraphFull_driver.h"

#include <sstream>
#include <deque>
#include <vector>
#include <string>

#include "c_types/line_graph_full_rt.h"
#include "cpp_common/pgdata_getters.hpp"
#include "cpp_common/alloc.hpp"
#include "cpp_common/assert.hpp"

#include "lineGraph/lineGraphFull.hpp"
#include "cpp_common/linear_directed_graph.hpp"

#include "dijkstra/dijkstra.hpp"

namespace {

void get_turn_penalty_postgres_result(
        std::vector< Line_graph_full_rt > edge_result,
        Line_graph_full_rt **return_tuples,
        size_t &sequence) {
    using pgrouting::pgr_alloc;
    (*return_tuples) = pgr_alloc(edge_result.size(), (*return_tuples));

    for (const auto &edge : edge_result) {
        (*return_tuples)[sequence] =
            {edge.id,
             edge.source,
             edge.target,
             edge.cost,
             edge.edge};
        sequence++;
    }
}

}  // namespace

void
pgr_do_lineGraphFull(
        const char *edges_sql,

        Line_graph_full_rt **return_tuples,
        size_t *return_count,
        char ** log_msg,
        char ** notice_msg,
        char ** err_msg) {
    using pgrouting::to_pg_msg;
    using pgrouting::pgr_free;

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

        hint = edges_sql;
        auto edges = pgrouting::pgget::get_edges(std::string(edges_sql), true, false);
        if (edges.empty()) {
            *notice_msg = to_pg_msg("No edges found");
            *log_msg = hint? to_pg_msg(hint) : to_pg_msg(log);
            return;
        }
        hint = nullptr;

        pgrouting::DirectedGraph digraph;
        digraph.insert_edges_neg(edges);

        pgrouting::graph::Pgr_lineGraphFull<
            pgrouting::LinearDirectedGraph,
            pgrouting::Line_vertex,
            pgrouting::Basic_edge, true> line(digraph);

        std::vector< Line_graph_full_rt > line_graph_edges;
        line_graph_edges = line.get_postgres_results_directed();

        auto count = line_graph_edges.size();

        if (count == 0) {
            (*return_tuples) = NULL;
            (*return_count) = 0;
            /* TODO change the notice message */
            notice <<
                "No paths found between start_vid and end_vid vertices";
        } else {
            size_t sequence = 0;

            get_turn_penalty_postgres_result(
                line_graph_edges,
                return_tuples,
                sequence);
            (*return_count) = sequence;
        }
#if 1
        log << line.log.str() << "\n\n\n";
        log << line << "\n";
#endif
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
